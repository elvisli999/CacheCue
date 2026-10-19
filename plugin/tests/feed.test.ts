import { expect, mock, test } from 'claude-code/testing'
import type { On, SessionUsage } from 'claude-code'

const START = Date.parse('2026-10-11T12:00:00Z')
const MINUTE = 60_000

const usage = (over: Partial<SessionUsage> = {}): SessionUsage => ({
  startedAt: START,
  context: { tokens: 68_600, window: 1_000_000, percent: 7 },
  rateLimits: [
    { kind: 'five_hour', percentUsed: 2.3, resetsAt: new Date(START + 276 * MINUTE).toISOString() },
    { kind: 'seven_day', percentUsed: 76.4, resetsAt: new Date(START + 836 * MINUTE).toISOString() },
  ],
  cost: { usd: 206.512 },
  ...over,
})

type Written = { path: string; text: string }

// The test's hooks stand for the engine beneath the mod.
const answerUsage = (
  on: On,
  figures: SessionUsage,
  host: { surface?: 'desktop' | 'terminal'; written?: Written[]; env?: Record<string, string> } = {},
) => {
  mock.env(on, { HOME: '/Users/t', ...host.env })
  on('session.usage', () => ({ value: figures }))
  on('session.id', () => ({ value: 's1' }))
  on('session.root', () => ({ value: '/Users/t/project' }))
  on('session.model', () => ({ value: 'claude-opus-5-5' }))
  on('session.surface', () => ({ value: host.surface ?? 'desktop' }))
  on('fs.write', (_, e) => {
    host.written?.push({ path: e.path, text: e.text })

    return { value: undefined }
  })
  on('turn.start', (_, e) => ({ turnId: e.turnId }))
  on('session.measure', (_, e) => ({ changed: e.changed }))
  on('session.start', (_, e) => ({ cwd: e.cwd }))
  on('turn.complete', (_, e) => ({ text: e.answer }))
  on('classic.Notification', () => ({}))
}

const START_INPUT = { cwd: '/tmp', surface: 'desktop', isInteractive: true } as const

const turn = (
  over: Partial<{ read: number; written: number; input: number; output: number; agentId: string }> = {},
) => ({
  answer: 'done',
  durationMs: 1000,
  isAborted: false,
  turnId: 't1',
  reason: 'answer' as const,
  ...(over.agentId === undefined ? {} : { agentId: over.agentId }),
  usage: {
    model: 'claude-opus-5-5',
    input_tokens: over.input ?? 100,
    output_tokens: over.output ?? 9_600,
    cache_read_input_tokens: over.read ?? 9_400,
    cache_creation_input_tokens: over.written ?? 500,
  },
})

const last = (written: Written[]) => JSON.parse(written.at(-1)?.text ?? '{}')

// What the mod said the session is doing, in the order it said it.
const states = (written: Written[]) =>
  written.filter(file => file.path.endsWith('.state.json')).map(file => JSON.parse(file.text))

test('leaves a snapshot for the menu bar, marked active while a turn runs', async ($, on) => {
  const clock = mock.clock(on, { now: START })
  const written: Written[] = []
  answerUsage(on, usage(), { written })
  await $.session.start(START_INPUT)
  // Loading is not activity: nothing is written until the session does something.
  expect(written).toHaveLength(0)

  await $.turn.start({ text: 'go', turnId: 't1' })
  expect(JSON.parse(written.at(-1)?.text ?? '{}')).toMatchObject({
    cache: { active: true },
    // The reading the mod found as it loaded is of unknown age.
    limits_at: null,
  })

  // A reading arriving mid-turn is fresh, and the turn is still running.
  await clock.advance(MINUTE)
  const fresh = usage()
  await $.session.measure({
    context: fresh.context,
    rateLimits: fresh.rateLimits,
    cost: fresh.cost,
    changed: ['rateLimits'],
  })
  expect(JSON.parse(written.at(-1)?.text ?? '{}')).toMatchObject({
    cache: { active: true },
    limits_at: (START + MINUTE) / 1000,
  })

  await clock.advance(MINUTE)
  await $.turn.complete(turn())

  expect(written.at(-1)?.path).toBe('/Users/t/Library/Caches/CacheCue/s1.json')
  expect(JSON.parse(written.at(-1)?.text ?? '{}')).toEqual({
    v: 1,
    source: 'desktop',
    session_id: 's1',
    cwd: '/Users/t/project',
    model_id: 'claude-opus-5-5',
    cache: {
      turn_hit: 94,
      avg_hit: 94,
      // A subscription's cache lives an hour from its last write.
      expires_at: (START + 62 * MINUTE) / 1000,
      active: false,
      ttl: 3600,
    },
    limits: {
      five_hour: { used: 2.3, resets_at: (START + 276 * MINUTE) / 1000 },
      seven_day: { used: 76.4, resets_at: (START + 836 * MINUTE) / 1000 },
    },
    limits_at: (START + MINUTE) / 1000,
    context: { tokens: 68_600, output: 9_600, window: 1_000_000, percent: 7 },
    cost_usd: 206.512,
    updated_at: (START + 2 * MINUTE) / 1000,
  })
})

test('in a terminal it says what the session is doing and leaves the figures to the status line command', async ($, on) => {
  const clock = mock.clock(on, { now: START })
  const written: Written[] = []
  answerUsage(on, usage(), { surface: 'terminal', written })
  await $.session.start({ ...START_INPUT, surface: 'terminal' })
  await $.turn.start({ text: 'go', turnId: 't1' })
  await clock.advance(MINUTE)
  await $.turn.complete(turn())

  expect(written.map(file => file.path)).toEqual([
    '/Users/t/Library/Caches/CacheCue/s1.state.json',
    '/Users/t/Library/Caches/CacheCue/s1.state.json',
  ])
  expect(states(written)).toEqual([
    { session_id: 's1', state: 'running', at: START / 1000, turns: 0, accepts: ['compact', 'warm', 'instructions'] },
    { session_id: 's1', state: 'idle', at: (START + MINUTE) / 1000, turns: 1, accepts: ['compact', 'warm', 'instructions'] },
  ])
})

test('an interrupted turn ends too, though it has no usage to count', async ($, on) => {
  mock.clock(on, { now: START })
  const written: Written[] = []
  answerUsage(on, usage(), { written })
  await $.session.start(START_INPUT)
  await $.turn.start({ text: 'go', turnId: 't1' })
  await $.turn.complete({ answer: '', durationMs: 500, isAborted: true, turnId: 't1', reason: 'aborted' })

  expect(states(written).at(-1)).toMatchObject({ state: 'idle' })
  expect(last(written)).toMatchObject({ cache: { active: false, turn_hit: null } })
})

test('a subagent starting a turn after the main one ended leaves the session idle', async ($, on) => {
  const clock = mock.clock(on, { now: START })
  const written: Written[] = []
  answerUsage(on, usage(), { written })
  await $.session.start(START_INPUT)
  await $.turn.start({ text: 'go', turnId: 't1' })
  await clock.advance(MINUTE)
  await $.turn.complete(turn())
  const before = written.length

  await clock.advance(MINUTE)
  await $.turn.start({ text: 'look', turnId: 't2', agentId: 'a1' } as Parameters<typeof $.turn.start>[0])

  expect(written).toHaveLength(before)
  expect(states(written).at(-1)).toMatchObject({ state: 'idle' })
  expect(last(written)).toMatchObject({ cache: { active: false } })
})

test('a prompt for permission marks the session as waiting; other notifications do not', async ($, on) => {
  mock.clock(on, { now: START })
  const written: Written[] = []
  answerUsage(on, usage(), { written })
  await $.session.start(START_INPUT)
  await $.classic.Notification({ message: 'Signed in', notification_type: 'auth_success' })
  expect(states(written)).toHaveLength(0)

  await $.classic.Notification({ message: 'Claude needs your permission', notification_type: 'permission_prompt' })
  expect(states(written)).toEqual([
    { session_id: 's1', state: 'waiting', at: START / 1000, turns: 0, accepts: ['compact', 'warm', 'instructions'] },
  ])
})

test('without a subscription window the cache is taken to live five minutes', async ($, on) => {
  mock.clock(on, { now: START })
  const written: Written[] = []
  const gateway = [{ kind: 'spend_limit', percentUsed: 62.8, resetsAt: new Date(START + 600 * MINUTE).toISOString() }]
  answerUsage(on, usage({ rateLimits: gateway }), { written })
  await $.session.start(START_INPUT)
  await $.turn.complete(turn())

  expect(last(written)).toMatchObject({
    cache: { ttl: 300, expires_at: (START + 5 * MINUTE) / 1000 },
    // A gateway's spend limit rides along with the windows.
    limits: { spend_limit: { used: 62.8, resets_at: (START + 600 * MINUTE) / 1000 } },
  })
})

test('a failed snapshot write does not cost the session its turn', async ($, on) => {
  mock.clock(on, { now: START })
  mock.env(on, { HOME: '/Users/t' })
  const logged: string[] = []
  on('session.usage', () => ({ value: usage() }))
  on('session.id', () => ({ value: 's1' }))
  on('session.root', () => ({ value: '/Users/t/project' }))
  on('session.surface', () => ({ value: 'desktop' }))
  on('fs.write', () => ({ deny: 'disk full' }))
  on('ui.log', (_, e) => {
    logged.push(e.text)

    return { value: undefined }
  })
  on('session.start', (_, e) => ({ cwd: e.cwd }))
  on('turn.complete', (_, e) => ({ text: e.answer }))
  await $.session.start(START_INPUT)

  expect(await $.turn.complete(turn())).toMatchObject({ text: 'done' })
  expect(logged.join('\n')).toContain('snapshot not written')
})

test('averages over turns, ignores subagents, and counts expiry from the last write', async ($, on) => {
  const clock = mock.clock(on, { now: START })
  const written: Written[] = []
  answerUsage(on, usage(), { written })
  await $.session.start(START_INPUT)

  // Turn 1 writes the cache and reads nothing: 0% hit.
  await $.turn.complete(turn({ read: 0, written: 900, input: 100 }))
  expect(last(written).cache).toMatchObject({ turn_hit: 0, avg_hit: 0, expires_at: (START + 60 * MINUTE) / 1000 })
  await clock.advance(50 * MINUTE)
  // A subagent's turn must not move the main conversation's figures.
  const before = written.length
  await $.turn.complete(turn({ read: 0, written: 50_000, input: 0, agentId: 'a1' }))
  expect(written).toHaveLength(before)
  // Turn 2 only reads: 100% this turn, 3000/4000 overall, and no new write to count from.
  await $.turn.complete(turn({ read: 3_000, written: 0, input: 0 }))
  expect(last(written).cache).toMatchObject({ turn_hit: 100, avg_hit: 75, expires_at: (START + 60 * MINUTE) / 1000 })
})

test('session.measure replaces the figures', async ($, on) => {
  mock.clock(on, { now: START })
  const written: Written[] = []
  answerUsage(on, usage(), { written })
  await $.session.start(START_INPUT)
  const next = usage({
    context: { tokens: 181_000, window: 200_000, percent: 91 },
    rateLimits: [{ kind: 'five_hour', percentUsed: 95, resetsAt: new Date(START + 25 * MINUTE).toISOString() }],
    cost: { usd: 3.5 },
  })
  await $.session.measure({
    context: next.context,
    rateLimits: next.rateLimits,
    cost: next.cost,
    changed: ['context', 'rateLimits', 'cost'],
  })

  expect(last(written)).toMatchObject({
    limits: { five_hour: { used: 95, resets_at: (START + 25 * MINUTE) / 1000 } },
    context: { tokens: 181_000, window: 200_000, percent: 91 },
    cost_usd: 3.5,
  })
  expect(last(written).limits.seven_day).toBeUndefined()
})

test('an account that is told no limits leaves them out, not zeros that look like data', async ($, on) => {
  mock.clock(on, { now: START })
  const written: Written[] = []
  answerUsage(on, usage({ context: { window: 200_000 }, rateLimits: [], cost: undefined }), { written })
  await $.session.start(START_INPUT)
  await $.turn.start({ text: 'go', turnId: 't1' })

  expect(last(written)).toMatchObject({
    limits: {},
    limits_at: null,
    context: { tokens: 0, window: 200_000, percent: null },
    cost_usd: null,
    cache: { turn_hit: null, avg_hit: null, expires_at: null, active: true, ttl: 300 },
  })
})

// The menu bar app's request for this session, as the mod finds it on disk.
const answerRequest = (on: On, request: Record<string, unknown> | null | (() => Record<string, unknown> | null)) => {
  const current = () => (typeof request === 'function' ? request() : request)
  on('fs.exists', (_, e) => ({ value: current() !== null && e.path.endsWith('/s1.request.json') }))
  on('fs.read', () => ({ value: JSON.stringify(current()) }))
}

const REQUEST = { v: 1, session_id: 's1', action: 'compact', id: 'r1', at: START / 1000 }

test('compacts when the menu bar app asks, once, and says what that took off the context', async ($, on) => {
  const clock = mock.clock(on, { now: START })
  const written: Written[] = []
  answerUsage(on, usage(), { surface: 'terminal', written })
  answerRequest(on, REQUEST)
  let compactions = 0
  on('session.compact', () => {
    compactions += 1

    return { messages: [{ role: 'user', text: 'summary', toolUses: [] }], tokensBefore: 310_000, tokensAfter: 24_000 }
  })
  await $.session.start({ ...START_INPUT, surface: 'terminal' })
  await $.turn.start({ text: 'go', turnId: 't1' })
  // Nothing is compacted under a running turn.
  await clock.advance(MINUTE)
  expect(compactions).toBe(0)

  await $.turn.complete(turn())
  await clock.advance(MINUTE)
  expect(compactions).toBe(1)
  expect(states(written).at(-1)).toMatchObject({
    state: 'idle',
    turns: 1,
    compact: { before: 310_000, after: 24_000, trigger: 'plugin', request: 'r1' },
  })
  expect(states(written).at(-1)).not.toHaveProperty('compact_failed')

  // The same request is not carried out twice.
  await clock.advance(MINUTE)
  expect(compactions).toBe(1)
})

test('a request for another session, or from a moment long past, is left alone', async ($, on) => {
  const clock = mock.clock(on, { now: START })
  answerUsage(on, usage())
  answerRequest(on, { ...REQUEST, at: START / 1000 - 600 })
  let compactions = 0
  on('session.compact', () => {
    compactions += 1

    return { messages: [{ role: 'user', text: 'summary', toolUses: [] }] }
  })
  await $.session.start(START_INPUT)
  await clock.advance(MINUTE)
  expect(compactions).toBe(0)
})

test('where the direct call is refused it runs the command, and says so when that fails too', async ($, on) => {
  const clock = mock.clock(on, { now: START })
  const written: Written[] = []
  answerUsage(on, usage(), { written })
  answerRequest(on, REQUEST)
  const commands: string[] = []
  on('session.compact', () => {
    throw new Error('not available in a headless session yet')
  })
  on('command.run', (_, e) => {
    commands.push(e.command)

    return { text: 'Error during compaction' }
  })
  await $.session.start(START_INPUT)
  await clock.advance(MINUTE)

  expect(commands).toEqual(['compact'])
  expect(states(written).at(-1)).toMatchObject({ compact_failed: { request: 'r1' } })
  expect(states(written).at(-1)).not.toHaveProperty('compact')
})

test('a compaction the person ran is noted too; a size the engine did not record comes from the measures around it', async ($, on) => {
  const clock = mock.clock(on, { now: START })
  const written: Written[] = []
  answerUsage(on, usage(), { written })
  answerRequest(on, null)
  on('session.compact', () => ({ messages: [{ role: 'user', text: 'summary', toolUses: [] }] }))
  await $.session.start(START_INPUT)
  await $.session.compact({ trigger: 'manual', messages: [{ role: 'user', text: 'hello', toolUses: [] }] })
  expect(states(written).at(-1)).toMatchObject({
    compact: { at: START / 1000, before: 68_600, after: null, trigger: 'manual' },
  })
  expect(states(written).at(-1)?.compact).not.toHaveProperty('request')
  // The summarising request read the cache: its countdown starts over.
  expect(last(written.filter(file => !file.path.endsWith('.state.json')))).toMatchObject({
    cache: { expires_at: START / 1000 + 3600 },
  })

  await clock.advance(MINUTE)
  const after = usage({ context: { tokens: 21_000, window: 1_000_000, percent: 2 } })
  await $.session.measure({ context: after.context, rateLimits: after.rateLimits, cost: after.cost, changed: ['context'] })
  expect(states(written).at(-1)).toMatchObject({ compact: { before: 68_600, after: 21_000 } })
})

test('after a compaction the context keeps the size it reported until a turn gives a new one', async ($, on) => {
  mock.clock(on, { now: START })
  const written: Written[] = []
  answerUsage(on, usage({ context: { tokens: 126_848, window: 1_000_000, percent: 13 } }), { written })
  answerRequest(on, null)
  on('session.compact', () => ({
    messages: [{ role: 'user', text: 'summary', toolUses: [] }],
    tokensBefore: 126_848,
    tokensAfter: 10_320,
  }))
  await $.session.start(START_INPUT)
  await $.session.compact({ trigger: 'manual', messages: [{ role: 'user', text: 'hello', toolUses: [] }] })
  // What the engine measures next has no size in it yet.
  const blank = usage({ context: { window: 1_000_000 } })
  await $.session.measure({ context: blank.context, rateLimits: blank.rateLimits, cost: blank.cost, changed: ['context'] })
  const snapshots = () => written.filter(file => !file.path.endsWith('.state.json'))
  expect(last(snapshots())).toMatchObject({ context: { tokens: 10_320 } })

  // Once a turn has run, a measure with no size means what it says.
  await $.turn.start({ text: 'go', turnId: 't1' })
  await $.turn.complete(turn())
  await $.session.measure({ context: blank.context, rateLimits: blank.rateLimits, cost: blank.cost, changed: ['context'] })
  expect(last(snapshots())).toMatchObject({ context: { tokens: 0 } })
})

// What a fork of the conversation answers: `read` is what the cache served.
const forked = (read: number) => ({
  isAnswered: true as const,
  text: 'OK',
  usage: {
    model: 'claude-opus-5-5',
    input_tokens: 12,
    output_tokens: 2,
    cache_read_input_tokens: read,
    cache_creation_input_tokens: 0,
  },
})

const WARM = { v: 1, session_id: 's1', action: 'warm', id: 'w1', at: START / 1000 }

test('keeps the cache warm when the app asks, without a word added to the conversation, and counts how often in a row', async ($, on) => {
  const clock = mock.clock(on, { now: START })
  const written: Written[] = []
  answerUsage(on, usage(), { written })
  let request: Record<string, unknown> | null = WARM
  answerRequest(on, () => request)
  const prompts: string[] = []
  on('model.fork', (_, e) => {
    prompts.push(e.prompt)

    return { value: forked(310_000) }
  })
  await $.session.start(START_INPUT)
  await clock.advance(MINUTE)

  expect(prompts).toEqual(['Reply with the single word OK.'])
  expect(states(written).at(-1)).toMatchObject({
    warm: { at: (START + 20_000) / 1000, request: 'w1', read: 310_000, count: 1 },
  })
  expect(states(written).at(-1)).not.toHaveProperty('warm_failed')

  // A second request is a second read in a row; the same one is not carried out twice.
  request = { ...WARM, id: 'w2', at: (START + MINUTE) / 1000 }
  await clock.advance(MINUTE)
  await clock.advance(MINUTE)
  expect(prompts).toHaveLength(2)
  expect(states(written).at(-1)).toMatchObject({ warm: { request: 'w2', count: 2 } })

  // Once the conversation moves, keeping warm counts from nothing again.
  request = null
  await $.turn.start({ text: 'go', turnId: 't1' })
  await $.turn.complete(turn())
  expect(states(written).at(-1)).not.toHaveProperty('warm')
  // The read moved the countdown on: the next snapshot runs an hour from the turn's own write.
  expect(last(written.filter(file => !file.path.endsWith('.state.json')))).toMatchObject({
    cache: { expires_at: (START + 3 * MINUTE) / 1000 + 3600 },
  })
})

test('a keep-warm read that the cache did not serve is a failure, not a warm cache', async ($, on) => {
  const clock = mock.clock(on, { now: START })
  const written: Written[] = []
  answerUsage(on, usage(), { written })
  answerRequest(on, WARM)
  on('model.fork', () => ({ value: forked(0) }))
  await $.session.start(START_INPUT)
  await clock.advance(MINUTE)

  expect(states(written).at(-1)).toMatchObject({ warm_failed: { request: 'w1', reason: 'cold' } })
  expect(states(written).at(-1)).not.toHaveProperty('warm')
})

test('a compaction the app asks for passes on what the summary should keep', async ($, on) => {
  const clock = mock.clock(on, { now: START })
  answerUsage(on, usage())
  answerRequest(on, { ...REQUEST, instructions: '  Keep the plan.  ' })
  const told: (string | undefined)[] = []
  on('session.compact', (_, e) => {
    told.push(e.instructions)

    return { messages: [{ role: 'user', text: 'summary', toolUses: [] }] }
  })
  await $.session.start(START_INPUT)
  await clock.advance(MINUTE)

  expect(told).toEqual(['Keep the plan.'])
})

test('where the direct call is refused, the instructions go after the command', async ($, on) => {
  const clock = mock.clock(on, { now: START })
  answerUsage(on, usage())
  answerRequest(on, { ...REQUEST, instructions: 'Keep the plan.' })
  const runs: string[] = []
  on('session.compact', () => {
    throw new Error('not available in a headless session yet')
  })
  on('command.run', (_, e) => {
    runs.push(`${e.command} ${e.args}`)

    return { text: '' }
  })
  await $.session.start(START_INPUT)
  await clock.advance(MINUTE)

  expect(runs).toEqual(['compact Keep the plan.'])
})

test("in a terminal it says when Claude Code's own idle compaction will take the session, and above what size", async ($, on) => {
  mock.clock(on, { now: START })
  const written: Written[] = []
  answerUsage(on, usage(), { surface: 'terminal', written, env: { CLAUDE_CODE_IDLE_COMPACT_MIN_TOKENS: '150000' } })
  answerRequest(on, null)
  on('session.version', () => ({ value: { version: '2.1.303', base: '2.1.303', builtAt: '2026-10-18T00:00:00Z' } }))
  let settings: Record<string, unknown> = {}
  on('settings.read', () => ({ value: settings }))
  await $.session.start({ ...START_INPUT, surface: 'terminal' })
  await $.turn.start({ text: 'go', turnId: 't1' })
  expect(states(written).at(-1)).toMatchObject({ idle_compact: { min_tokens: 150_000 } })

  // Turned off in /config, it is no longer said.
  settings = { idleCompaction: false }
  await $.turn.complete(turn())
  expect(states(written).at(-1)).not.toHaveProperty('idle_compact')
})

test('a Claude Code from before idle compaction, or the desktop app, says nothing of it', async ($, on) => {
  mock.clock(on, { now: START })
  const written: Written[] = []
  answerUsage(on, usage(), { surface: 'terminal', written })
  answerRequest(on, null)
  on('session.version', () => ({ value: { version: '2.1.296', base: '2.1.296', builtAt: '2026-10-10T00:00:00Z' } }))
  on('settings.read', () => ({ value: {} }))
  await $.session.start({ ...START_INPUT, surface: 'terminal' })
  await $.turn.start({ text: 'go', turnId: 't1' })
  expect(states(written).at(-1)).not.toHaveProperty('idle_compact')
})
