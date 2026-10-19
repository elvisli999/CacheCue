import { atom, read, update } from 'claude-code'
import type { EngineInterface, ModelUsage, Register, SessionUsage } from 'claude-code'

import type { CacheStats, Figures, Limit } from '../types'

// The plugin draws nothing: it only leaves each session's figures, and what the session is
// doing, where the CacheCue menu bar app reads them.
const HOUR_MS = 60 * 60 * 1000
const FIVE_MINUTES_MS = 5 * 60 * 1000
// The windows only a subscription is told; a gateway's spend limit is kept too.
const PLAN_WINDOWS = ['five_hour', 'seven_day']
const LIMIT_KINDS = [...PLAN_WINDOWS, 'spend_limit']
// What Claude Code notifies about when it is the person's move.
const WAITING_ON = ['permission_prompt', 'idle_prompt', 'agent_needs_input', 'elicitation_dialog']
// Where the menu bar app looks; the terminal's status line command writes here too.
const SNAPSHOT_DIR = 'Library/Caches/CacheCue'
// How often the mod looks for something the menu bar app asked of this session.
const REQUEST_POLL_MS = 20 * 1000
// A request older than this was meant for a moment that has passed.
const REQUEST_FRESH_S = 180
// What the mod does when the menu bar app asks; the app asks only of a session that says so.
// `instructions`: a compaction asked for may say what the summary should keep.
const ACCEPTS = ['compact', 'warm', 'instructions']
// What a keep-warm request adds after the transcript. The reply is thrown away: the request
// is only there to read the cache, which then lives another lifetime from that moment.
const WARM_PROMPT = 'Reply with the single word OK.'
// Claude Code compacts an idle terminal conversation itself from this release on, above this
// many tokens unless `CLAUDE_CODE_IDLE_COMPACT_MIN_TOKENS` says otherwise.
const IDLE_COMPACT_SINCE = [2, 1, 299]
const IDLE_COMPACT_MIN_TOKENS = 200_000
// A summary told more than this is being told too much.
const INSTRUCTIONS_MAX = 600

type SessionActivity = 'running' | 'idle' | 'waiting'

// Something the menu bar app asked of this session.
type Request = { id: string; action: 'compact' | 'warm'; instructions?: string }

// The last time a keep-warm request read the cache, and how many in a row there have been
// since the main conversation last moved.
type Warm = { at: number; request: string; read: number; count: number }

// The last compaction of the main conversation: its two sizes, never what was said.
type Compaction = {
  at: number
  before: number | null
  after: number | null
  trigger: string
  request?: string
}

const NO_STATS: CacheStats = {
  turnRead: 0,
  turnTotal: 0,
  sumRead: 0,
  sumTotal: 0,
  turnOutput: 0,
  writeAt: null,
}

const cache = atom({ plugin: 'cachecue', key: 'cache' } as const, NO_STATS)
const figures = atom({ plugin: 'cachecue', key: 'figures' } as const, null)

const hitPercent = (readTokens: number, total: number): number | null =>
  total > 0 ? Math.round((readTokens * 100) / total) : null

const inputTokens = (usage: ModelUsage): number =>
  usage.input_tokens + usage.cache_read_input_tokens + usage.cache_creation_input_tokens

const toFigures = (
  usage: Pick<SessionUsage, 'context' | 'rateLimits' | 'cost'>,
  measuredAt: number | null,
): Figures => ({
  measuredAt,
  tokens: usage.context.tokens,
  window: usage.context.window,
  percent: usage.context.percent,
  limits: usage.rateLimits.map(limit => ({
    kind: limit.kind,
    percentUsed: limit.percentUsed,
    resetsAt: limit.resetsAt,
  })),
  usd: usage.cost?.usd,
})

// The mod is never told how long a cache write lives. A subscription's main conversation
// gets an hour; an API key, a cloud provider or a gateway gets five minutes. Having a
// 5-hour or 7-day window is what tells a subscription apart: a guess, and the menu bar app
// treats it as one.
const cacheLifetimeMs = (limits: Limit[]): number =>
  limits.some(limit => PLAN_WINDOWS.includes(limit.kind)) ? HOUR_MS : FIVE_MINUTES_MS

const toEpochSeconds = (iso: string | undefined): number | null => {
  const ms = iso === undefined ? Number.NaN : Date.parse(iso)

  return Number.isNaN(ms) ? null : Math.round(ms / 1000)
}

// Leaves this session's figures for the menu bar app. A turn in flight is
// `active`: its requests keep the cache in use until it ends. Written only when the
// session did something, so `updated_at` says which session is the live one.
async function writeSnapshot($: EngineInterface, isActive: boolean): Promise<void> {
  try {
    const surface = await $.session.surface()
    const home = await $.env.get('HOME')
    // In a terminal the status line command writes this session's file.
    if (surface === 'terminal' || home === undefined) {
      return
    }
    const id = await $.session.id()
    const stats = await read($, cache)
    const held = await read($, figures)
    const limits: Record<string, { used: number; resets_at: number | null }> = {}
    for (const limit of held?.limits ?? []) {
      if (LIMIT_KINDS.includes(limit.kind)) {
        limits[limit.kind] = { used: limit.percentUsed, resets_at: toEpochSeconds(limit.resetsAt) }
      }
    }
    const lifetime = cacheLifetimeMs(held?.limits ?? [])
    const snapshot = {
      // Still 1: fields were only added, and an app older than this plugin must keep reading.
      v: 1,
      source: surface ?? 'desktop',
      session_id: id,
      // The project root, which names the session; a shell `cd` mid-session moves cwd, not this.
      cwd: await $.session.root(),
      model_id: await $.session.model(),
      cache: {
        turn_hit: hitPercent(stats.turnRead, stats.turnTotal),
        avg_hit: hitPercent(stats.sumRead, stats.sumTotal),
        expires_at: stats.writeAt === null ? null : Math.round((stats.writeAt + lifetime) / 1000),
        active: isActive,
        ttl: lifetime / 1000,
      },
      limits,
      // The limits are the account's and every session holds its own last reading:
      // this is how the app tells the freshest one.
      limits_at: held?.measuredAt == null ? null : Math.round(held.measuredAt / 1000),
      context: {
        tokens: held?.tokens ?? 0,
        output: stats.turnOutput,
        window: held?.window ?? 0,
        percent: held?.percent ?? null,
      },
      cost_usd: held?.usd ?? null,
      updated_at: Math.round((await $.clock.now()) / 1000),
    }
    await $.fs.write(`${home}/${SNAPSHOT_DIR}/${id}.json`, JSON.stringify(snapshot))
  } catch (error) {
    // The menu bar going stale must not cost the session its hook.
    $.ui.log(`cachecue: snapshot not written: ${String(error)}`, { to: 'debug' })
  }
}

// What the mod says beside the snapshot (`<session_id>.state.json`): what the session is
// doing, how many turns it has finished, and how its last compaction went. In a terminal
// this is all the mod writes: the status line command there is never told whether a turn is
// running or Claude Code is waiting on the person.
type Note = {
  state: SessionActivity
  turns: number
  compact: Compaction | null
  failed: { at: number; request: string } | null
  warm: Warm | null
  warmFailed: { at: number; request: string; reason: string } | null
  /** Claude Code's own idle compaction will take this session above this many tokens. */
  idleCompactMin: number | null
}

async function writeNote($: EngineInterface, note: Note): Promise<void> {
  try {
    const home = await $.env.get('HOME')
    if (home === undefined) {
      return
    }
    const id = await $.session.id()
    const file = {
      session_id: id,
      state: note.state,
      at: Math.round((await $.clock.now()) / 1000),
      turns: note.turns,
      accepts: ACCEPTS,
      ...(note.compact === null ? {} : { compact: note.compact }),
      ...(note.failed === null ? {} : { compact_failed: note.failed }),
      ...(note.warm === null ? {} : { warm: note.warm }),
      ...(note.warmFailed === null ? {} : { warm_failed: note.warmFailed }),
      ...(note.idleCompactMin === null ? {} : { idle_compact: { min_tokens: note.idleCompactMin } }),
    }
    await $.fs.write(`${home}/${SNAPSHOT_DIR}/${id}.state.json`, JSON.stringify(file))
  } catch (error) {
    $.ui.log(`cachecue: state not written: ${String(error)}`, { to: 'debug' })
  }
}

// What the menu bar app asked of this session, if it asked just now. The app decides when;
// the rules and thresholds are its own.
async function pendingRequest($: EngineInterface): Promise<Request | null> {
  const home = await $.env.get('HOME')
  if (home === undefined) {
    return null
  }
  const id = await $.session.id()
  const path = `${home}/${SNAPSHOT_DIR}/${id}.request.json`
  if (!(await $.fs.exists(path))) {
    return null
  }
  const request: unknown = JSON.parse(await $.fs.read(path))
  if (typeof request !== 'object' || request === null) {
    return null
  }
  const { action, session_id: sessionId, id: requestId, at, instructions } = request as Record<string, unknown>
  const now = (await $.clock.now()) / 1000
  if (
    (action !== 'compact' && action !== 'warm') ||
    sessionId !== id ||
    typeof requestId !== 'string' ||
    typeof at !== 'number' ||
    now - at > REQUEST_FRESH_S
  ) {
    return null
  }
  const told = typeof instructions === 'string' ? instructions.trim().slice(0, INSTRUCTIONS_MAX) : ''

  return { id: requestId, action, ...(action === 'compact' && told !== '' ? { instructions: told } : {}) }
}

// `2.1.303` or `2.1.303-dev` against a release such as [2, 1, 299].
function isAtLeast(base: string, least: number[]): boolean {
  const parts = (base.split('-')[0] ?? '').split('.').map(Number)
  for (const [index, part] of least.entries()) {
    const own = parts[index] ?? 0
    if (Number.isNaN(own)) {
      return false
    }
    if (own !== part) {
      return own > part
    }
  }

  return true
}

// Whether Claude Code will compact this session itself once it sits idle, and above what
// size: only in a terminal, only from 2.1.299, and not where the settings turn it off.
async function idleCompaction($: EngineInterface): Promise<number | null> {
  try {
    if ((await $.session.surface()) !== 'terminal') {
      return null
    }
    const { base } = await $.session.version()
    if (base === undefined || !isAtLeast(base, IDLE_COMPACT_SINCE)) {
      return null
    }
    const settings = await $.settings.read()
    if (settings.idleCompaction === false) {
      return null
    }
    const chosen = Number(await $.env.get('CLAUDE_CODE_IDLE_COMPACT_MIN_TOKENS'))

    return Number.isFinite(chosen) && chosen > 0 ? chosen : IDLE_COMPACT_MIN_TOKENS
  } catch {
    // An engine that cannot say is taken not to do it.
    return null
  }
}

// What the mod keeps between hooks. A reload starts it over, and reloads fall between turns.
type Live = {
  /** Main-thread turn in flight. */
  isWorking: boolean
  activity: SessionActivity
  /** Main-thread turns finished since the mod loaded. */
  turns: number
  compaction: Compaction | null
  /** `turns` as the last compaction ended: until a turn follows, the engine has no size of its own. */
  turnsAtCompaction: number | null
  failed: { at: number; request: string } | null
  warm: Warm | null
  warmFailed: { at: number; request: string; reason: string } | null
  idleCompactMin: number | null
  /** The request being carried out, and the last one taken up: each is acted on once. */
  carrying: string | null
  lastRequest: string | null
  isWatching: boolean
}

function say($: EngineInterface, live: Live, state: SessionActivity): Promise<void> {
  live.activity = state

  return writeNote($, {
    state,
    turns: live.turns,
    compact: live.compaction,
    failed: live.failed,
    warm: live.warm,
    warmFailed: live.warmFailed,
    idleCompactMin: live.idleCompactMin,
  })
}

// Keeps a compaction's two sizes. Where the engine recorded none, the context as last
// measured stands for the size before, and the next measure fills in the size after.
async function noteCompaction(
  $: EngineInterface,
  live: Live,
  trigger: string,
  before: number | undefined,
  after: number | undefined,
): Promise<void> {
  try {
    const at = await $.clock.now()
    const held = await read($, figures)
    live.compaction = {
      at: Math.round(at / 1000),
      before: before ?? held?.tokens ?? null,
      after: after ?? null,
      trigger,
      ...(live.carrying === null ? {} : { request: live.carrying }),
    }
    live.failed = null
    // Keeping warm starts counting again from a conversation that moved.
    live.warm = null
    live.warmFailed = null
    live.turnsAtCompaction = live.turns
    // The summarising request read the cache, which keeps it for another lifetime.
    await update($, cache, stats => ({ ...stats, writeAt: at }))
    if (after !== undefined) {
      await update($, figures, kept => (kept === null ? kept : { ...kept, tokens: after }))
    }
    await say($, live, live.activity)
    await writeSnapshot($, live.isWorking)
  } catch (error) {
    $.ui.log(`cachecue: compaction not noted: ${String(error)}`, { to: 'debug' })
  }
}

// Compacts the conversation because the menu bar app asked: the person turned that on
// for this session there. `$.session.compact` is the direct call; a session with no
// interface of its own (the desktop app's) refuses it and runs the command instead.
async function compactFor($: EngineInterface, live: Live, request: string, instructions?: string): Promise<void> {
  live.carrying = request
  try {
    let direct: Awaited<ReturnType<typeof $.session.compact>> | null = null
    try {
      direct = await $.session.compact(instructions === undefined ? undefined : { instructions })
    } catch {
      await $.command.run({ command: 'compact', ...(instructions === undefined ? {} : { args: instructions }) })
    }
    if (direct !== null && direct.skip === undefined) {
      // The mod's own call does not come through its own hook.
      await noteCompaction($, live, 'plugin', direct.tokensBefore, direct.tokensAfter)
    }
  } catch (error) {
    $.ui.log(`cachecue: compaction asked for did not run: ${String(error)}`, { to: 'debug' })
  }
  // Run as a command, a compaction that stood came through the `session.compact` hook.
  if (live.compaction?.request !== request) {
    live.failed = { at: Math.round((await $.clock.now()) / 1000), request }
    await say($, live, live.activity)
  }
  live.carrying = null
}

// Keeps the cache warm because the menu bar app asked: the person chose that for this
// session there. A fork of the conversation as last sent reads the whole prefix from the
// cache and is never added to the conversation; only a read that the cache served counts.
async function warmFor($: EngineInterface, live: Live, request: string): Promise<void> {
  live.carrying = request
  const now = await $.clock.now()
  const at = Math.round(now / 1000)
  try {
    const reply = await $.model.fork({ prompt: WARM_PROMPT })
    const read = reply.isAnswered ? reply.usage.cache_read_input_tokens : 0
    if (read > 0) {
      live.warm = { at, request, read, count: (live.warm?.count ?? 0) + 1 }
      live.warmFailed = null
      // The read keeps the cache for another lifetime from now.
      await update($, cache, stats => ({ ...stats, writeAt: now }))
    } else {
      // Answered with nothing read, the cache had already gone: the whole prefix was written again.
      live.warmFailed = { at, request, reason: reply.isAnswered ? 'cold' : reply.reason }
    }
  } catch (error) {
    live.warmFailed = { at, request, reason: 'unavailable' }
    $.ui.log(`cachecue: keeping warm did not run: ${String(error)}`, { to: 'debug' })
  }
  await say($, live, live.activity)
  live.carrying = null
}

function watchRequests($: EngineInterface, live: Live): void {
  if (live.isWatching) {
    return
  }
  live.isWatching = true
  $.clock.every(REQUEST_POLL_MS, () => {
    // Nothing can be compacted while a turn runs, or while one compaction is under way.
    if (live.isWorking || live.carrying !== null) {
      return
    }
    void (async () => {
      try {
        const request = await pendingRequest($)
        if (request !== null && request.id !== live.lastRequest) {
          live.lastRequest = request.id
          if (request.action === 'warm') {
            await warmFor($, live, request.id)
          } else {
            await compactFor($, live, request.id, request.instructions)
          }
        }
      } catch (error) {
        $.ui.log(`cachecue: request not read: ${String(error)}`, { to: 'debug' })
      }
    })()
  })
}

export const register: Register = on => {
  const live: Live = {
    isWorking: false,
    activity: 'idle',
    turns: 0,
    compaction: null,
    turnsAtCompaction: null,
    failed: null,
    warm: null,
    warmFailed: null,
    idleCompactMin: null,
    carrying: null,
    lastRequest: null,
    isWatching: false,
  }

  on('session.start', async ($, e, next) => {
    watchRequests($, live)
    live.idleCompactMin = await idleCompaction($)
    // What the engine holds as the mod loads is its last reading, of unknown age:
    // keep the time of one the mod itself saw arrive, when it is the same reading.
    const loaded = toFigures(await $.session.usage(), null)
    await update($, figures, held =>
      held !== null && JSON.stringify(held.limits) === JSON.stringify(loaded.limits)
        ? { ...loaded, measuredAt: held.measuredAt }
        : loaded,
    )

    // Loaded mid-session, the last turn's hit rate is still on the live window.
    const stats = await read($, cache)
    if (stats.turnTotal === 0) {
      const { context } = await $.session.usage({ breakdown: 'summary' })
      const last = context.breakdown?.apiUsage
      if (last) {
        await update($, cache, held => ({
          ...held,
          turnRead: last.cache_read_input_tokens,
          turnTotal: inputTokens(last),
          turnOutput: last.output_tokens,
        }))
      }
    }

    return next(e)
  })

  on('session.measure', async ($, e, next) => {
    const at = await $.clock.now()
    const measured = toFigures(e, at)
    // Right after a compaction the engine has no size to give until the next response
    // arrives: the size the compaction itself reported stands, not a nought.
    const known = live.turnsAtCompaction === live.turns ? live.compaction?.after : null
    await update($, figures, () =>
      measured.tokens === undefined && known != null ? { ...measured, tokens: known } : measured,
    )
    // The first measure after a compaction says how small the conversation became.
    if (live.compaction !== null && live.compaction.after === null && e.context.tokens !== undefined) {
      live.compaction = { ...live.compaction, after: e.context.tokens }
      await say($, live, live.activity)
    }
    await writeSnapshot($, live.isWorking)

    return next(e)
  })

  on('turn.start', async ($, e, next) => {
    // A subagent's turn is not the main conversation's: Claude Code 2.1.299 began telling
    // plugins of those too, and only the main turn's end would ever mark the session idle.
    // Read through a cast, since the builds before 2.1.299 do not declare the field.
    if ((e as { agentId?: string }).agentId === undefined) {
      live.isWorking = true
      await say($, live, 'running')
      await writeSnapshot($, true)
    }

    return next(e)
  })

  on('turn.complete', async ($, e, next) => {
    // A subagent's turn is not the main conversation's.
    if (e.agentId === undefined) {
      const usage = e.usage
      // An interrupted turn ends with no usage to count, and ends all the same.
      if (usage !== undefined) {
        const at = await $.clock.now()
        const total = inputTokens(usage)
        await update($, cache, held => ({
          turnRead: usage.cache_read_input_tokens,
          turnTotal: total,
          sumRead: held.sumRead + usage.cache_read_input_tokens,
          sumTotal: held.sumTotal + total,
          turnOutput: usage.output_tokens,
          writeAt: usage.cache_creation_input_tokens > 0 ? at : held.writeAt,
        }))
        live.turns += 1
      }
      live.warm = null
      live.warmFailed = null
      // `/config` may have turned Claude Code's idle compaction on or off since.
      live.idleCompactMin = await idleCompaction($)
      live.isWorking = false
      await say($, live, 'idle')
      await writeSnapshot($, false)
    }

    return next(e)
  })

  // Every compaction of the main conversation, whoever asked for it. The event carries the
  // conversation itself: it is handed on untouched, and only its two sizes are kept.
  on('session.compact', async ($, e, next) => {
    const result = await next(e)
    if (e.agentId === undefined && e.trigger !== 'precompute' && result.skip === undefined) {
      await noteCompaction($, live, e.trigger, result.tokensBefore, result.tokensAfter)
    }

    return result
  }).catch((_, e, next) => next(e))

  // Claude Code's own notifications say when it is the person's move.
  on('classic.Notification', async ($, e, next) => {
    if (WAITING_ON.includes(e.notification_type)) {
      await say($, live, 'waiting')
    }

    return next(e)
    // Whatever goes wrong here, the notification itself must still go out.
  }).catch((_, e, next) => next(e))
}
