import Foundation

/// What to do for a session as its cache is about to go cold, as the person chose on its card.
public enum BeforeExpiry: String, CaseIterable {
    /// Nothing: the cache goes cold, and coming back rewrites it.
    case leave
    /// Read the cache once more, so that it lives another lifetime; nothing is lost.
    case warm
    /// Compact the conversation, so that coming back rewrites only the summary.
    case compact
}

/// Acting for the person before a session's cache goes cold: keeping it warm, or compacting
/// it. Off unless they chose one for that session, because both cost and compacting throws
/// detail away for good. The app decides when and leaves a request; the plugin in the
/// session carries it out.
public enum AutoCompact {
    /// How long before the cache runs out a compaction is asked for: late enough that the
    /// person has plainly stepped away, early enough for the summary to be written from a warm cache.
    public static let lead: TimeInterval = 300
    /// A keep-warm read is a single small request, so it can wait longer.
    public static let warmLead: TimeInterval = 180
    /// With less than this left, the request would not reach the cache in time.
    public static let tooLate: TimeInterval = 45
    /// A request the plugin has not answered in this long is taken back.
    public static let requestLife: TimeInterval = 600
    /// Kept warm this many times in a row with nothing else happening, about three hours, the
    /// person is taken not to be coming back soon, and the cache is let go.
    public static let maxWarms = 3
    /// Claude Code's own idle compaction comes after about 54 minutes idle: about this long
    /// before a one-hour cache runs out.
    public static let claudeCodeLead: TimeInterval = 360

    /// A five-minute cache runs out during any pause: acting at each would be absurd.
    public static func isOffered(for session: SessionView) -> Bool {
        session.lifetime >= 3600
    }

    /// Claude Code will compact this session itself before its cache goes cold, so the app
    /// leaves it alone rather than act twice.
    public static func isTakenByClaudeCode(_ session: SessionView) -> Bool {
        guard let least = session.idleCompactMin else { return false }
        return session.source == "terminal" && session.lifetime >= 3600 && session.contextTokens >= least
    }

    /// What the person can do from a notification about this session: the actions its
    /// plugin carries out, where the app would carry them out at all.
    public static func actions(for session: SessionView) -> [BeforeExpiry] {
        guard isOffered(for: session), !isTakenByClaudeCode(session) else { return [] }
        return (session.acceptsWarm ? [.warm] : []) + (session.acceptsCompact ? [.compact] : [])
    }

    /// One request to make now.
    public struct Due: Equatable {
        public var session: SessionView
        public var action: BeforeExpiry
    }

    /// The requests to make now. Each cache is asked about once: `ledger` holds, by session,
    /// the expiry a request was last made for. `choices` holds what the person chose, by session.
    public static func due(sessions: [SessionView], choices: [String: BeforeExpiry], ledger: inout [String: Double]) -> [Due] {
        var due: [Due] = []
        for session in sessions {
            guard let choice = choices[session.id], choice != .leave,
                  isOffered(for: session), !isTakenByClaudeCode(session), session.isIdle,
                  session.contextTokens >= CompactAdvice.smallContext,
                  case .expires(let left) = session.cache, left > tooLate,
                  let expiresAt = session.expiresAt, ledger[session.id] != expiresAt
            else { continue }
            switch choice {
            case .compact:
                guard session.acceptsCompact, left <= lead else { continue }
            case .warm:
                guard session.acceptsWarm, left <= warmLead, (session.lastWarm?.count ?? 0) < maxWarms else { continue }
            case .leave:
                continue
            }
            ledger[session.id] = expiresAt
            due.append(Due(session: session, action: choice))
        }
        let listed = Set(sessions.map(\.id))
        ledger = ledger.filter { listed.contains($0.key) }
        return due
    }

    /// Where a session stands with what the person chose for it.
    public enum Status: Equatable {
        /// The plugin in the session is too old to be asked, or the session has none.
        case needsPlugin
        /// Waiting for the moment.
        case armed
        /// Compacted on the app's request.
        case done(SessionState.Compaction)
        /// A request did not go through, and nothing has been compacted since.
        case failed
        /// Kept warm on the app's request.
        case warmed(SessionState.Warm)
        case warmFailed
        /// Claude Code compacts the session itself, at about this moment (epoch seconds).
        case claudeCode(at: Double?)
    }

    public static func status(of session: SessionView, choice: BeforeExpiry) -> Status {
        if isTakenByClaudeCode(session) {
            return .claudeCode(at: session.expiresAt.map { $0 - claudeCodeLead })
        }
        switch choice {
        case .leave:
            return .armed
        case .compact:
            guard session.acceptsCompact else { return .needsPlugin }
            if let failed = session.compactFailed, failed.at >= (session.lastCompact?.at ?? 0) { return .failed }
            if let compact = session.lastCompact, compact.request != nil { return .done(compact) }
            return .armed
        case .warm:
            guard session.acceptsWarm else { return .needsPlugin }
            if let failed = session.warmFailed, failed.at >= (session.lastWarm?.at ?? 0) { return .warmFailed }
            if let warm = session.lastWarm { return .warmed(warm) }
            return .armed
        }
    }
}

extension SessionView {
    /// What to say under the choice for this session's cache; nil where there is nothing to say.
    public func beforeExpiryLine(_ strings: Strings, choice: BeforeExpiry, now: Date, calendar: Calendar = .current) -> String? {
        func time(_ at: Double) -> String { Format.clock(Date(timeIntervalSince1970: at), now: now, calendar: calendar) }
        switch AutoCompact.status(of: self, choice: choice) {
        case .claudeCode(let at): return String(format: strings.claudeCodeCompacts, at.map(time) ?? "--:--")
        case .needsPlugin: return strings.autoCompactNeedsPlugin
        case .armed:
            switch choice {
            case .leave: return nil
            case .compact: return String(format: strings.autoCompactNote, Int(AutoCompact.lead / 60))
            case .warm: return String(format: strings.warmNote, Int(AutoCompact.warmLead / 60), AutoCompact.maxWarms)
            }
        case .failed: return strings.autoCompactFailed
        case .warmFailed: return strings.warmFailed
        case .warmed(let warm): return String(format: strings.warmDone, time(warm.at), warm.count, AutoCompact.maxWarms)
        case .done(let compact):
            var line = String(format: strings.autoCompactDone, time(compact.at))
            if let before = compact.before, let after = compact.after {
                line += " · \(Format.tokens(before)) → \(Format.tokens(after))"
            }
            return line
        }
    }

    /// What each choice costs at list prices: `Back cold $2.40 · compact ≈$0.48 · warm 1h $0.06`.
    /// Nil for a model without a known price.
    public func expiryCostLine(_ strings: Strings, isSubscription: Bool) -> String? {
        guard let costs = ExpiryCosts(tokens: coldCost.tokens, modelID: modelID, lifetime: lifetime) else { return nil }
        let line = String(
            format: strings.expiryCosts, ColdCost.dollars(costs.coldUSD), ColdCost.dollars(costs.compactUSD),
            ColdCost.dollars(costs.warmUSD))
        return isSubscription ? line + " · " + strings.costEquivalent : line
    }
}
