import XCTest

@testable import CacheCueCore

final class AutoCompactTests: XCTestCase {
    let now = Date(timeIntervalSince1970: 1_791_750_000)
    var at: Double { now.timeIntervalSince1970 }
    var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }

    func snapshot(
        _ id: String = "a", expiresIn: Double? = 240, tokens: Double = 310_000, ttl: Double? = 3600, cost: Double? = nil,
        updatedAgo: Double = 900
    ) -> Snapshot {
        Snapshot(
            v: 1, source: "desktop", sessionID: id, cwd: "/Users/t/Code/\(id)-app",
            cache: .init(turnHit: 90, avgHit: 90, expiresAt: expiresIn.map { at + $0 }, active: false, ttl: ttl),
            limits: [:], limitsAt: nil,
            context: .init(tokens: tokens, output: 0, window: 1_000_000, percent: nil),
            costUSD: cost, updatedAt: at - updatedAgo)
    }

    func note(
        _ id: String = "a", _ state: String = SessionState.idle, accepts: [String]? = ["compact"], turns: Int? = nil,
        compact: SessionState.Compaction? = nil, failed: SessionState.Failure? = nil
    ) -> SessionState {
        SessionState(
            sessionID: id, state: state, at: at - 900, turns: turns, accepts: accepts, compact: compact, compactFailed: failed)
    }

    func session(
        _ id: String = "a", expiresIn: Double? = 240, tokens: Double = 310_000, ttl: Double? = 3600,
        state: SessionState? = nil, plain: Bool = false
    ) -> SessionView {
        Summary.view(
            of: snapshot(id, expiresIn: expiresIn, tokens: tokens, ttl: ttl), at: at, state: plain ? nil : state ?? note(id))
    }

    func limit(_ used: Double) -> LimitView {
        LimitView(label: "5h", percent: Int(used.rounded()), used: used, bar: "", reset: nil, resetsIn: 7200, level: .ok, resetsAt: at + 7200)
    }

    // MARK: When to compact

    func testAnIdleSessionAboutToGoColdIsCompactedOncePerExpiry() {
        var ledger: [String: Double] = [:]
        let first = AutoCompact.due(sessions: [session()], choices: ["a": .compact], ledger: &ledger)
        XCTAssertEqual(first.map(\.session.id), ["a"])
        XCTAssertEqual(ledger, ["a": at + 240])
        XCTAssertTrue(AutoCompact.due(sessions: [session()], choices: ["a": .compact], ledger: &ledger).isEmpty)
        // A later expiry is another cache, and gets its own request.
        XCTAssertEqual(AutoCompact.due(sessions: [session(expiresIn: 200)], choices: ["a": .compact], ledger: &ledger).count, 1)
        // A session no longer listed is forgotten.
        _ = AutoCompact.due(sessions: [], choices: ["a": .compact], ledger: &ledger)
        XCTAssertEqual(ledger, [:])
    }

    func testOnlyWhereThePersonTurnedItOnAndThePluginCanDoIt() {
        func due(_ session: SessionView, choices: [String: BeforeExpiry] = ["a": .compact]) -> Bool {
            var ledger: [String: Double] = [:]
            return !AutoCompact.due(sessions: [session], choices: choices, ledger: &ledger).isEmpty
        }
        XCTAssertTrue(due(session()))
        XCTAssertFalse(due(session(), choices: [:]))
        XCTAssertFalse(due(session(), choices: ["b": .compact]))
        // No plugin's note, or one from a plugin that does not take requests.
        XCTAssertFalse(due(session(plain: true)))
        XCTAssertFalse(due(session(state: note(accepts: nil))))
        // A turn running, or Claude Code waiting on the person, is a turn in flight.
        XCTAssertFalse(due(session(state: note("a", SessionState.waiting))))
        XCTAssertFalse(due(Summary.view(
            of: snapshot(updatedAgo: 5), at: at,
            state: SessionState(sessionID: "a", state: SessionState.running, at: at - 5, accepts: ["compact"]))))
    }

    func testNotTooEarlyNotTooLateNotOnALittleContextOrAFiveMinuteCache() {
        func due(_ session: SessionView) -> Bool {
            var ledger: [String: Double] = [:]
            return !AutoCompact.due(sessions: [session], choices: ["a": .compact], ledger: &ledger).isEmpty
        }
        XCTAssertFalse(due(session(expiresIn: 301)))
        XCTAssertTrue(due(session(expiresIn: 300)))
        XCTAssertTrue(due(session(expiresIn: 46)))
        XCTAssertFalse(due(session(expiresIn: 45)))
        XCTAssertFalse(due(session(expiresIn: -10)))
        XCTAssertFalse(due(session(expiresIn: nil)))
        XCTAssertFalse(due(session(tokens: 49_000)))
        XCTAssertTrue(due(session(tokens: 50_000)))
        XCTAssertFalse(due(session(expiresIn: 60, ttl: 300)))
        XCTAssertFalse(AutoCompact.isOffered(for: session(ttl: 300)))
        XCTAssertTrue(AutoCompact.isOffered(for: session()))
    }

    func testWhatIsSaidUnderTheChoiceToCompact() {
        let strings = Strings.of(.en)
        func line(_ state: SessionState?, plain: Bool = false) -> String? {
            session(state: state, plain: plain).beforeExpiryLine(strings, choice: .compact, now: now, calendar: calendar)
        }
        XCTAssertEqual(AutoCompact.status(of: session(plain: true), choice: .compact), .needsPlugin)
        XCTAssertEqual(line(nil, plain: true), strings.autoCompactNeedsPlugin)
        XCTAssertEqual(
            line(note()),
            "Runs /compact here once this session sits idle with 5 minutes of cache left. Compacting drops detail and cannot be undone.")
        // One the person ran themselves is not the app's doing.
        XCTAssertEqual(AutoCompact.status(of: session(state: note(compact: .init(at: at - 60, before: 310_000, after: 24_000, trigger: "manual"))), choice: .compact), .armed)
        let done = SessionState.Compaction(at: at - 3600, before: 310_000, after: 24_000, trigger: "plugin", request: "r1")
        XCTAssertEqual(line(note(compact: done)), "Compacted for you at 19:20 · 310.0k → 24.0k")
        XCTAssertEqual(line(note(compact: .init(at: at - 3600, trigger: "manual", request: "r1"))), "Compacted for you at 19:20")
        // A failure since the last compaction is what stands.
        XCTAssertEqual(line(note(compact: done, failed: .init(at: at - 60, request: "r2"))), strings.autoCompactFailed)
        XCTAssertEqual(AutoCompact.status(of: session(state: note(compact: done, failed: .init(at: at - 7200, request: "r0"))), choice: .compact), .done(done))
    }

    // MARK: The files

    func testTheNoteAndTheRequestAsTheyAreOnDisk() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("cachecue-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        // As the plugin writes it.
        let text = """
        {"session_id":"a","state":"idle","at":1791749000,"turns":7,"accepts":["compact"],
         "compact":{"at":1791748000,"before":310000,"after":24000,"trigger":"plugin","request":"r1"},
         "compact_failed":{"at":1791747000,"request":"r0"}}
        """
        try Data(text.utf8).write(to: directory.appendingPathComponent("a.state.json"))
        // An older plugin's note has none of the new fields.
        try Data(#"{"session_id":"b","state":"running","at":1791749000}"#.utf8)
            .write(to: directory.appendingPathComponent("b.state.json"))
        let states = SnapshotStore.loadStates(from: directory)
        XCTAssertEqual(states["a"]?.turns, 7)
        XCTAssertEqual(states["a"]?.compact, .init(at: 1_791_748_000, before: 310_000, after: 24_000, trigger: "plugin", request: "r1"))
        XCTAssertEqual(states["a"]?.compactFailed, .init(at: 1_791_747_000, request: "r0"))
        XCTAssertEqual(states["b"], SessionState(sessionID: "b", state: "running", at: 1_791_749_000))

        try SnapshotStore.write(SessionRequest(sessionID: "a", action: "compact", id: "r2", at: at), in: directory)
        try SnapshotStore.write(SessionRequest(sessionID: "b", action: "compact", id: "r3", at: at - 700), in: directory)
        try SnapshotStore.write(SessionRequest(sessionID: "c", action: "compact", id: "r4", at: at), in: directory)
        let file = directory.appendingPathComponent("a.request.json")
        let written = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(contentsOf: file)) as? [String: Any])
        XCTAssertEqual(written["v"] as? Int, 1)
        XCTAssertEqual(written["session_id"] as? String, "a")
        XCTAssertEqual(written["action"] as? String, "compact")
        XCTAssertEqual(written["id"] as? String, "r2")
        XCTAssertEqual(written["at"] as? Double, at)
        // Neither a note nor a request is taken for a snapshot.
        XCTAssertTrue(SnapshotStore.load(from: directory).isEmpty)

        // One answered and one left too long go; the fresh one stays for the plugin.
        SnapshotStore.clearRequests(in: directory, answered: ["r4"], now: now, life: AutoCompact.requestLife)
        let left = try FileManager.default.contentsOfDirectory(atPath: directory.path).filter { $0.hasSuffix(".request.json") }
        XCTAssertEqual(left, ["a.request.json"])
    }

    // MARK: What the week adds up

    func testCompactionsAreCountedOnceTheirSizeAfterwardsIsKnown() {
        var history = History()
        history.record(snapshots: [snapshot()], states: ["a": note()], now: now, calendar: calendar)
        // Compacted, but nothing has said yet how small it became.
        var compact = SessionState.Compaction(at: at + 10, before: 310_000, after: nil, trigger: "manual")
        history.record(snapshots: [snapshot()], states: ["a": note(compact: compact)], now: now.addingTimeInterval(12), calendar: calendar)
        XCTAssertEqual(history.week(now: now, calendar: calendar).compacts, 0)
        compact.after = 24_000
        for _ in 0..<2 {
            history.record(snapshots: [snapshot()], states: ["a": note(compact: compact)], now: now.addingTimeInterval(20), calendar: calendar)
        }
        let week = history.week(now: now, calendar: calendar)
        XCTAssertEqual(week.compacts, 1)
        XCTAssertEqual(week.compactSaved, 286_000)
        XCTAssertFalse(week.isEmpty)
        XCTAssertEqual(week.compactLine(.of(.en)), "Compacts 1 · context down by 286.0k tokens")
        XCTAssertNil(Week().compactLine(.of(.en)))
    }

    func testACompactionFromBeforeTheFirstLookIsNotCounted() {
        var history = History()
        let old = SessionState.Compaction(at: at - 5000, before: 310_000, after: 24_000, trigger: "manual")
        history.record(snapshots: [snapshot()], states: ["a": note(compact: old)], now: now, calendar: calendar)
        // A session that turns up later with an old compaction on its note is the same.
        history.record(
            snapshots: [snapshot(), snapshot("b")], states: ["a": note(compact: old), "b": note("b", compact: old)],
            now: now.addingTimeInterval(4), calendar: calendar)
        XCTAssertEqual(history.week(now: now, calendar: calendar).compacts, 0)
    }

    func testHistoryWrittenBeforeTheseWereKeptStillReads() throws {
        let old = """
        {"v":1,"samples":{},"since":1791700000,
         "days":{"2026-10-13":{"coldStarts":1,"coldTokens":200000,"rebuilds":0,"rebuildTokens":0,"hits":{},"projects":{}}},
         "sessions":{"a":{"misses":0,"missTokens":0,"cost":3,"coldTokens":200000,"wasCold":false}}}
        """
        let history = try JSONDecoder().decode(History.self, from: Data(old.utf8))
        XCTAssertEqual(history.days["2026-10-13"]?.coldStarts, 1)
        XCTAssertNil(history.sessions["a"]?.turns)
        XCTAssertNil(history.turnShare(of: "a"))
    }

    // MARK: A turn's share of the limit

    func testWhatTheLimitGrewByGoesToTheOneSessionAtWork() {
        var history = History()
        var moment = now
        func look(_ used: Double, turns: [String: Int], cost: [String: Double]) {
            moment = moment.addingTimeInterval(2)
            history.record(
                snapshots: cost.keys.sorted().map { snapshot($0, cost: cost[$0]) },
                states: Dictionary(uniqueKeysWithValues: turns.map { ($0.key, note($0.key, turns: $0.value)) }),
                fiveHour: limit(used), now: moment, calendar: calendar)
        }
        look(10, turns: ["a": 0, "b": 0], cost: ["a": 1, "b": 1])
        // Three turns of `a` alone take three percent.
        look(11, turns: ["a": 1, "b": 0], cost: ["a": 2, "b": 1])
        look(12, turns: ["a": 2, "b": 0], cost: ["a": 3, "b": 1])
        XCTAssertNil(history.turnShare(of: "a"))
        look(13, turns: ["a": 3, "b": 0], cost: ["a": 4, "b": 1])
        XCTAssertEqual(history.turnShare(of: "a") ?? 0, 1, accuracy: 0.0001)
        XCTAssertNil(history.turnShare(of: "b"))
        // With both at work nobody can say whose it was: the turn counts, the percent does not.
        look(17, turns: ["a": 4, "b": 1], cost: ["a": 5, "b": 2])
        XCTAssertEqual(history.turnShare(of: "a") ?? 0, 0.75, accuracy: 0.0001)
        // The limit growing with nobody at work was used somewhere else.
        look(30, turns: ["a": 4, "b": 1], cost: ["a": 5, "b": 2])
        XCTAssertEqual(history.turnShare(of: "a") ?? 0, 0.75, accuracy: 0.0001)
        // A plugin that loaded again counts from nought, and is not taken for turns undone.
        look(30, turns: ["a": 0, "b": 1], cost: ["a": 5, "b": 2])
        look(31, turns: ["a": 1, "b": 1], cost: ["a": 6, "b": 2])
        XCTAssertEqual(history.turnShare(of: "a") ?? 0, 0.8, accuracy: 0.0001)
        // A session gone from the list takes its tally with it.
        look(31, turns: ["b": 1], cost: ["b": 2])
        XCTAssertNil(history.burn?["a"])
    }

    func testTheShareAsTheCardSaysIt() {
        var view = session()
        XCTAssertNil(view.turnShareLine(.of(.en)))
        view.turnShare = 0.84
        XCTAssertEqual(view.turnShareLine(.of(.en)), "Lately about 0.8% of the 5-hour limit per turn")
        view.turnShare = 12.4
        XCTAssertEqual(view.turnShareLine(.of(.zhHans)), "最近每轮约占 5 小时额度的 12%")
        var summary = Summary(snapshots: [snapshot(updatedAgo: 5), snapshot("b", updatedAgo: 50)], now: now)
        var history = History()
        history.burn = ["b": .init(percent: 6, turns: 4)]
        summary.setTurnShares(from: history)
        XCTAssertNil(summary.current?.turnShare)
        XCTAssertEqual(summary.others.first?.turnShare, 1.5)
    }

    // MARK: Cold sessions, and sessions waiting

    func testAColdSessionSaysWhatTakingItUpAgainRewrites() {
        let strings = Strings.of(.en)
        let cold = session(expiresIn: -60, plain: true)
        XCTAssertEqual(cold.resumeLine(strings), "Resuming rewrites ~310.0k tokens")
        XCTAssertEqual(cold.coldLine(strings), "Resuming rewrites ~310.0k tokens · ≥20× the price of reading them warm")
        // Warm, it is still something that may happen; small, it is not worth a line.
        XCTAssertNil(session(plain: true).resumeLine(strings))
        XCTAssertEqual(session(plain: true).coldLine(strings), "Going cold rewrites ~310.0k tokens · ≥20× the price of reading them warm")
        XCTAssertNil(session(expiresIn: -60, tokens: 20_000, plain: true).resumeLine(strings))
    }

    func testASessionTheListHasNoRoomForIsWatchedAllTheSame() {
        // Seven sessions, and the idle one about to go cold is the oldest of them.
        let busy = (1...6).map { snapshot("s\($0)", expiresIn: 3000, updatedAgo: Double($0) * 10) }
        let summary = Summary(snapshots: busy + [snapshot()], now: now, states: ["a": note()])
        XCTAssertFalse(summary.sessions.contains { $0.id == "a" })
        XCTAssertEqual(summary.unlisted.map(\.id), ["a"])
        var ledger: [String: Double] = [:]
        XCTAssertEqual(AutoCompact.due(sessions: summary.every, choices: ["a": .compact], ledger: &ledger).map(\.session.id), ["a"])
        var alerts = AlertLedger()
        let due = Alerts.due(
            sessions: summary.every, limits: [:], now: now, lead: 600, cache: true, quota: false, ledger: &alerts)
        XCTAssertEqual(due.compactMap(\.sessionID), ["a"])
    }

    func testAnySessionWaitingShowsInTheMenuBar() {
        let waiting = SessionState(sessionID: "b", state: SessionState.waiting, at: at - 40)
        let snapshots = [snapshot(updatedAgo: 5), snapshot("b", updatedAgo: 50)]
        XCTAssertTrue(Summary(snapshots: snapshots, now: now, states: ["b": waiting]).isAnyWaiting)
        XCTAssertFalse(Summary(snapshots: snapshots, now: now).isAnyWaiting)
    }
}
