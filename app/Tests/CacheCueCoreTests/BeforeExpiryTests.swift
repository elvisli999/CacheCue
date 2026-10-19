import XCTest

@testable import CacheCueCore

/// Keeping a cache warm, compacting, or leaving a session to Claude Code's own idle compaction.
final class BeforeExpiryTests: XCTestCase {
    let now = Date(timeIntervalSince1970: 1_791_750_000)
    var at: Double { now.timeIntervalSince1970 }
    var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }

    func snapshot(
        _ id: String = "a", source: String = "desktop", expiresIn: Double? = 150, tokens: Double = 310_000,
        ttl: Double? = 3600, model: String? = nil
    ) -> Snapshot {
        var snapshot = Snapshot(
            v: 1, source: source, sessionID: id, cwd: "/Users/t/Code/\(id)-app",
            cache: .init(turnHit: 90, avgHit: 90, expiresAt: expiresIn.map { at + $0 }, active: false, ttl: ttl),
            limits: [:], limitsAt: nil,
            context: .init(tokens: tokens, output: 0, window: 1_000_000, percent: nil),
            costUSD: nil, updatedAt: at - 3400)
        snapshot.modelID = model
        return snapshot
    }

    func note(
        _ id: String = "a", accepts: [String]? = ["compact", "warm", "instructions"], warm: SessionState.Warm? = nil,
        warmFailed: SessionState.WarmFailure? = nil, idleCompact: Double? = nil
    ) -> SessionState {
        SessionState(
            sessionID: id, state: SessionState.idle, at: at - 3400, accepts: accepts, warm: warm, warmFailed: warmFailed,
            idleCompact: idleCompact.map { .init(minTokens: $0) })
    }

    func session(
        source: String = "desktop", expiresIn: Double? = 150, tokens: Double = 310_000, ttl: Double? = 3600,
        model: String? = nil, state: SessionState? = nil
    ) -> SessionView {
        Summary.view(
            of: snapshot(source: source, expiresIn: expiresIn, tokens: tokens, ttl: ttl, model: model), at: at,
            state: state ?? note())
    }

    func due(_ session: SessionView, _ choice: BeforeExpiry) -> [AutoCompact.Due] {
        var ledger: [String: Double] = [:]
        return AutoCompact.due(sessions: [session], choices: ["a": choice], ledger: &ledger)
    }

    // MARK: Keeping warm

    func testAnIdleSessionIsKeptWarmLateAndOncePerExpiry() {
        XCTAssertEqual(due(session(), .warm).map(\.action), [.warm])
        // Later than a compaction would come: three minutes, not five.
        XCTAssertTrue(due(session(expiresIn: 181), .warm).isEmpty)
        XCTAssertEqual(due(session(expiresIn: 181), .compact).map(\.action), [.compact])
        XCTAssertTrue(due(session(expiresIn: 45), .warm).isEmpty)
        // Left alone, nothing is asked.
        XCTAssertTrue(due(session(), .leave).isEmpty)
        // A plugin that cannot keep warm is not asked to.
        XCTAssertTrue(due(session(state: note(accepts: ["compact"])), .warm).isEmpty)

        var ledger: [String: Double] = [:]
        XCTAssertEqual(AutoCompact.due(sessions: [session()], choices: ["a": .warm], ledger: &ledger).count, 1)
        XCTAssertTrue(AutoCompact.due(sessions: [session()], choices: ["a": .warm], ledger: &ledger).isEmpty)
    }

    func testAReadThatKeptTheCacheStartsItsHourOver() {
        // The status line still says the cache ran out; the plugin's note says it was read since.
        let warmed = session(expiresIn: -60, state: note(warm: .init(at: at - 100, request: "w1", read: 310_000, count: 1)))
        XCTAssertEqual(warmed.cache, .expires(in: 3500))
        XCTAssertEqual(warmed.expiresAt, at + 3500)
        // A read older than the cache's own expiry changes nothing.
        let stale = session(expiresIn: 150, state: note(warm: .init(at: at - 3500, request: "w0", count: 1)))
        XCTAssertEqual(stale.cache, .expires(in: 150))
    }

    func testKeptWarmThreeTimesInARowTheCacheIsLetGo() {
        let twice = note(warm: .init(at: at - 3450, request: "w2", count: 2))
        XCTAssertEqual(due(session(state: twice), .warm).count, 1)
        let thrice = note(warm: .init(at: at - 3450, request: "w3", count: 3))
        XCTAssertTrue(due(session(state: thrice), .warm).isEmpty)
    }

    func testWhatIsSaidUnderTheChoiceToKeepWarm() {
        let strings = Strings.of(.en)
        func line(_ state: SessionState) -> String? {
            session(state: state).beforeExpiryLine(strings, choice: .warm, now: now, calendar: calendar)
        }
        XCTAssertEqual(
            line(note()),
            "Rereads the cache with a one-line request once this session sits idle with 3 minutes left, up to 3 times in a row. Nothing is added to the conversation.")
        let warm = SessionState.Warm(at: at - 3450, request: "w2", read: 310_000, count: 2)
        XCTAssertEqual(line(note(warm: warm)), "Kept warm at 19:22 · 2 of 3")
        // A failure since the last read is what stands.
        XCTAssertEqual(line(note(warm: warm, warmFailed: .init(at: at - 60, request: "w3", reason: "cold"))), strings.warmFailed)
        XCTAssertEqual(line(note(accepts: ["compact"])), strings.autoCompactNeedsPlugin)
        XCTAssertNil(session().beforeExpiryLine(strings, choice: .leave, now: now, calendar: calendar))
    }

    // MARK: Claude Code's own idle compaction

    func testATerminalSessionClaudeCodeWillCompactIsLeftToIt() {
        let taken = session(source: "terminal", state: note(idleCompact: 200_000))
        XCTAssertTrue(AutoCompact.isTakenByClaudeCode(taken))
        XCTAssertTrue(due(taken, .compact).isEmpty)
        XCTAssertTrue(due(taken, .warm).isEmpty)
        XCTAssertEqual(AutoCompact.actions(for: taken), [])
        XCTAssertEqual(AutoCompact.status(of: taken, choice: .leave), .claudeCode(at: at + 150 - 360))
        XCTAssertEqual(
            taken.beforeExpiryLine(.of(.en), choice: .warm, now: now, calendar: calendar),
            "Claude Code compacts this session itself at about 20:16. To choose here instead, turn off Idle compaction in /config.")

        // Below its threshold, or where it does not run, the choice is the person's again.
        let small = session(source: "terminal", tokens: 150_000, state: note(idleCompact: 200_000))
        XCTAssertFalse(AutoCompact.isTakenByClaudeCode(small))
        XCTAssertEqual(due(small, .warm).count, 1)
        XCTAssertFalse(AutoCompact.isTakenByClaudeCode(session(state: note(idleCompact: 200_000))))
        XCTAssertFalse(AutoCompact.isTakenByClaudeCode(session(source: "terminal")))
    }

    func testANotificationOffersWhatThePluginCanDo() {
        XCTAssertEqual(AutoCompact.actions(for: session()), [.warm, .compact])
        XCTAssertEqual(AutoCompact.actions(for: session(state: note(accepts: ["compact"]))), [.compact])
        XCTAssertEqual(AutoCompact.actions(for: session(state: note(accepts: nil))), [])
        XCTAssertEqual(AutoCompact.actions(for: session(ttl: 300)), [])
    }

    // MARK: What each choice costs

    func testWhatEachChoiceCosts() throws {
        // Opus 5.5: $4 a million input, reads at 0.05×, one-hour writes at 2×, output at 5×.
        let costs = try XCTUnwrap(ExpiryCosts(tokens: 300_000, modelID: "claude-opus-5-5", lifetime: 3600))
        XCTAssertEqual(costs.coldUSD, 2.4, accuracy: 0.0001)
        XCTAssertEqual(costs.warmUSD, 0.06, accuracy: 0.0001)
        XCTAssertEqual(costs.compactUSD, 0.06 + 0.3 + 0.12, accuracy: 0.0001)
        XCTAssertNil(ExpiryCosts(tokens: 300_000, modelID: "some-other-model", lifetime: 3600))

        let view = session(tokens: 300_000, model: "claude-opus-5-5")
        XCTAssertEqual(view.expiryCostLine(.of(.en), isSubscription: false), "Resume cold $2.40 · compact ≈$0.48 · warm 1h $0.06")
        XCTAssertEqual(
            view.expiryCostLine(.of(.en), isSubscription: true),
            "Resume cold $2.40 · compact ≈$0.48 · warm 1h $0.06 · API-rate value")
        XCTAssertNil(session().expiryCostLine(.of(.en), isSubscription: false))
    }

    // MARK: The files

    func testTheNewFieldsAsTheyAreOnDisk() throws {
        let text = """
        {"session_id":"a","state":"idle","at":1791749000,"turns":7,"accepts":["compact","warm","instructions"],
         "warm":{"at":1791748000,"request":"w1","read":310000,"count":2},
         "warm_failed":{"at":1791747000,"request":"w0","reason":"cold"},
         "idle_compact":{"min_tokens":150000}}
        """
        let state = try JSONDecoder().decode(SessionState.self, from: Data(text.utf8))
        XCTAssertEqual(state.warm, .init(at: 1_791_748_000, request: "w1", read: 310_000, count: 2))
        XCTAssertEqual(state.warmFailed, .init(at: 1_791_747_000, request: "w0", reason: "cold"))
        XCTAssertEqual(state.idleCompact, .init(minTokens: 150_000))
        let view = Summary.view(of: snapshot(), at: at, state: state)
        XCTAssertTrue(view.acceptsWarm)
        XCTAssertTrue(view.acceptsInstructions)
        XCTAssertEqual(view.idleCompactMin, 150_000)

        let asked = SessionRequest(sessionID: "a", action: SessionRequest.compact, id: "r1", at: at, instructions: "Keep the plan.")
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(asked)) as? [String: Any])
        XCTAssertEqual(object["instructions"] as? String, "Keep the plan.")
        let warm = SessionRequest(sessionID: "a", action: SessionRequest.warm, id: "w2", at: at)
        let plain = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(warm)) as? [String: Any])
        XCTAssertEqual(plain["action"] as? String, "warm")
        XCTAssertNil(plain["instructions"])
    }

    func testEveryLanguageHasTheNewWords() {
        for language in Language.allCases {
            let strings = Strings.of(language)
            for text in [
                strings.beforeExpiry, strings.choiceLeave, strings.choiceWarm, strings.choiceCompact, strings.warmFailed,
                strings.compactInstructions, strings.compactInstructionsNote,
            ] {
                XCTAssertFalse(text.isEmpty, language.rawValue)
            }
            // The placeholders each format takes, in order.
            XCTAssertEqual(String(format: strings.warmNote, 3, 3).contains("3"), true, language.rawValue)
            XCTAssertEqual(strings.warmNote.components(separatedBy: "%d").count, 3, language.rawValue)
            XCTAssertEqual(strings.warmDone.components(separatedBy: "%@").count, 2, language.rawValue)
            XCTAssertEqual(strings.warmDone.components(separatedBy: "%d").count, 3, language.rawValue)
            XCTAssertEqual(strings.claudeCodeCompacts.components(separatedBy: "%@").count, 2, language.rawValue)
            XCTAssertEqual(strings.expiryCosts.components(separatedBy: "%@").count, 4, language.rawValue)
        }
    }
}
