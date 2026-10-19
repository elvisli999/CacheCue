import Foundation

public enum Level: Equatable {
    case plain, ok, warn, crit
}

public enum Format {
    public static let barCells = 8

    public static func tokens(_ count: Double) -> String {
        if count >= 1_000_000 { return String(format: "%.1fM", count / 1_000_000) }
        if count >= 1_000 { return String(format: "%.1fk", count / 1_000) }
        return String(Int(count.rounded()))
    }

    /// `4d2h`, `4h36m`, `38m`.
    public static func reset(_ interval: TimeInterval) -> String {
        let seconds = max(0, Int(interval))
        let days = seconds / 86400
        let hours = seconds % 86400 / 3600
        let minutes = seconds % 3600 / 60
        if days > 0 { return "\(days)d\(hours)h" }
        if hours > 0 { return "\(hours)h" + String(format: "%02dm", minutes) }
        return "\(minutes)m"
    }

    /// `47:36`.
    public static func countdown(_ interval: TimeInterval) -> String {
        let seconds = max(0, Int(interval))
        return String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }

    public static func filledCells(_ percent: Double) -> Int {
        let filled = min(barCells, max(0, Int((percent * Double(barCells) / 100).rounded())))
        return percent > 0 && filled == 0 ? 1 : filled
    }

    public static func bar(_ percent: Double) -> String {
        let filled = filledCells(percent)
        return String(repeating: "▰", count: filled) + String(repeating: "▱", count: barCells - filled)
    }

    public static func level(_ percent: Double, warn: Double, crit: Double) -> Level {
        percent >= crit ? .crit : percent >= warn ? .warn : .ok
    }

    public static func hitLevel(_ percent: Int) -> Level {
        percent < 50 ? .crit : percent < 80 ? .warn : .ok
    }
}

/// An account-wide rate-limit window, ready to draw.
public struct LimitView: Equatable {
    public var label: String
    public var percent: Int
    /// 0 to 100, unrounded.
    public var used: Double
    public var bar: String
    public var reset: String?
    /// Seconds until the window resets.
    public var resetsIn: TimeInterval?
    public var level: Level
    /// Epoch seconds of the reset, which tells one window from the next.
    public var resetsAt: Double? = nil
    /// A gateway's spend limit may say what was spent and what the limit is.
    public var usedUSD: Double? = nil
    public var limitUSD: Double? = nil
    /// Where the bar would stand if the window were being used evenly, 0 to 1.
    public var evenMark: Double? = nil
    /// Where the present rate of use leads.
    public var pace: Pace? = nil
}

/// Where a session's prompt cache stands.
public enum CacheState: Equatable {
    case unknown
    case active
    case expires(in: TimeInterval)
    case expired

    /// How long a cache entry lives when the session does not say: an hour, as on a
    /// subscription. An API key's lives five minutes.
    public static let lifetime: TimeInterval = 3600

    /// With this little left, stepping away means losing the cache: ten minutes of an
    /// hour, a minute and a half of five minutes.
    public static func warnWindow(lifetime: TimeInterval) -> TimeInterval { min(600, lifetime * 0.3) }
    public static func critWindow(lifetime: TimeInterval) -> TimeInterval { min(120, lifetime * 0.1) }

    /// What is left of the hour, 0 to 1.
    public var remainingFraction: Double { remainingFraction(of: CacheState.lifetime) }

    /// What is left of a cache that lives `lifetime`, 0 to 1.
    public func remainingFraction(of lifetime: TimeInterval) -> Double {
        switch self {
        case .unknown, .expired: return 0
        case .active: return 1
        case .expires(let left): return min(1, max(0, left / lifetime))
        }
    }

    /// The menu bar's short form: `47:36`, `live`, `exp`, `--:--`.
    public var shortText: String {
        switch self {
        case .unknown: return "--:--"
        case .active: return "live"
        case .expires(let left): return Format.countdown(left)
        case .expired: return "exp"
        }
    }

    public var text: String {
        switch self {
        case .unknown: return "--:--"
        case .active: return "active"
        case .expires(let left): return Format.countdown(left)
        case .expired: return "expired"
        }
    }

    public var level: Level { level(lifetime: CacheState.lifetime) }

    public func level(lifetime: TimeInterval) -> Level {
        switch self {
        case .unknown, .active: return .plain
        case .expires(let left):
            return left <= CacheState.critWindow(lifetime: lifetime) ? .crit
                : left <= CacheState.warnWindow(lifetime: lifetime) ? .warn : .plain
        case .expired: return .crit
        }
    }
}

public struct SessionView: Equatable {
    /// The session's id, which pinning goes by.
    public var id: String
    public var name: String
    /// `terminal`, `desktop`, ...
    public var source: String
    public var turnHit: Int?
    public var avgHit: Int?
    public var cache: CacheState
    public var contextTokens: Double
    public var contextWindow: Double
    public var contextPercent: Double?
    public var output: Double
    public var costUSD: Double?
    /// The project folder; `name` is the session's own name when it has one.
    public var folder: String = ""
    /// How long this session's cache entries live.
    public var lifetime: TimeInterval = CacheState.lifetime
    /// The lifetime is a guess: only the status line command is told it, and only by a
    /// Claude Code recent enough.
    public var lifetimeIsEstimate = false
    /// Epoch seconds the cache runs out, which tells one stretch of it from the next.
    public var expiresAt: Double? = nil
    /// Claude Code's count of what a cold cache rewrites; nil when it gave none.
    public var recacheTokens: Double? = nil
    public var misses: Int = 0
    public var missTokens: Double = 0
    public var lastMissCauses: [String] = []
    public var model: String? = nil
    public var modelID: String? = nil
    public var effort: String? = nil
    public var isFast = false
    public var worktree: String? = nil
    /// Claude Code is waiting on the person: a permission prompt, or an idle prompt.
    public var isWaiting = false
    /// The plugin says no turn is running. Without a plugin's note nothing says so.
    public var isIdle = false
    /// The plugin in this session compacts when the app asks.
    public var acceptsCompact = false
    /// The session's last compaction, and one the app asked for that did not go through.
    public var lastCompact: SessionState.Compaction? = nil
    public var compactFailed: SessionState.Failure? = nil
    /// The plugin in this session keeps the cache warm when the app asks, and passes on what a
    /// compaction's summary should keep.
    public var acceptsWarm = false
    public var acceptsInstructions = false
    /// The last read that kept the cache warm, and one that did not.
    public var lastWarm: SessionState.Warm? = nil
    public var warmFailed: SessionState.WarmFailure? = nil
    /// Claude Code compacts this terminal session itself once it sits idle, at this size and above.
    public var idleCompactMin: Double? = nil
    /// The share of the 5-hour limit a turn of this session has been taking lately, in
    /// percent; nil with too few turns to go by.
    public var turnShare: Double? = nil

    public var cacheLevel: Level { cache.level(lifetime: lifetime) }
    public var cacheFraction: Double { cache.remainingFraction(of: lifetime) }
    /// `5m` or `1h`, as Claude Code names the two cache lifetimes; `~1h` for a guess.
    public var lifetimeLabel: String {
        (lifetimeIsEstimate ? "~" : "") + (lifetime >= 3600 ? "1h" : "\(Int(lifetime / 60))m")
    }

    /// What letting the cache go cold costs: Claude Code's own count where it gave one,
    /// the context's size otherwise.
    public var coldCost: ColdCost {
        ColdCost(
            tokens: recacheTokens ?? contextTokens, isEstimate: recacheTokens == nil, modelID: modelID,
            lifetime: lifetime)
    }

    /// Beside the name: the folder when the session has its own name, then the model (with
    /// a bolt in fast mode), the effort and the worktree.
    public var subtitle: String {
        let parts: [String?] = [
            folder == name ? nil : folder, model.map { isFast ? $0 + " ⚡" : $0 }, effort, worktree.map { "⎇ " + $0 },
        ]
        return parts.compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " · ")
    }
}

public struct TitlePart: Equatable {
    public var text: String
    public var level: Level

    public init(_ text: String, _ level: Level = .plain) {
        self.text = text
        self.level = level
    }
}

public struct Summary: Equatable {
    /// A session silent for longer than this is not listed.
    public static let sessionWindow: TimeInterval = 24 * 3600
    public static let maxOthers = 5
    /// A session that said a turn was running and then went silent this long has died.
    public static let activeGrace: TimeInterval = 6 * 3600

    /// A turn said to be running by the plugin's note, with no figure moving for this
    /// long, is taken to have stopped: an interrupt leaves no note.
    public static let runningGrace: TimeInterval = 600

    public var fiveHour: LimitView?
    public var sevenDay: LimitView?
    /// A gateway's spend limit, which an account without the two windows may have instead.
    public var spendLimit: LimitView?
    /// The session shown in full: the pinned one, or else the one that last did something.
    public var current: SessionView?
    public var others: [SessionView]
    /// Sessions still alive that the list has no room for. Not drawn, and watched all the
    /// same: the one sitting idle longest is the one whose cache runs out first.
    public var unlisted: [SessionView] = []
    /// `current` was chosen by the person, not by recency.
    public var isPinned = false
    /// `current` was chosen because its cache is about to go cold, not by recency.
    public var isUrgent = false
    /// Some session has a 5-hour or 7-day reading, which only a subscription gives. The
    /// dollar figure is then a value at API list prices, not a bill.
    public var isSubscription = false

    /// `pinned` is a session id the person chose to keep in view; it stands for as long as
    /// that session is still listed. With `followsUrgent`, a session about to lose a cache
    /// worth keeping comes before the one that last did something. `states` are the
    /// plugin's notes on what each session is doing.
    public init(
        snapshots: [Snapshot], now: Date, pinned: String? = nil, states: [String: SessionState] = [:],
        followsUrgent: Bool = false
    ) {
        let at = now.timeIntervalSince1970
        let newestFirst = snapshots.sorted { $0.updatedAt > $1.updatedAt }

        // The limits are the account's, but each session only knows what its own last
        // API response said, so the readings disagree. The one received last stands; a
        // reading of unknown age ranks below any dated one, then by its session's
        // activity. A window already past its reset says nothing.
        func limit(_ kind: String, label: String) -> LimitView? {
            let readings = newestFirst.compactMap { snapshot -> (limit: Snapshot.Limit, at: Double)? in
                guard let found = snapshot.limits[kind] else { return nil }
                if let resetsAt = found.resetsAt, resetsAt <= at { return nil }
                return (found, snapshot.limitsAt ?? 0)
            }
            // `max` keeps the first of equals, and the readings are newest session first.
            guard let freshest = readings.max(by: { $0.at < $1.at })?.limit else { return nil }
            return LimitView(
                label: label,
                percent: Int(freshest.used.rounded()),
                used: freshest.used,
                bar: Format.bar(freshest.used),
                reset: freshest.resetsAt.map { Format.reset($0 - at) },
                resetsIn: freshest.resetsAt.map { $0 - at },
                level: Format.level(freshest.used, warn: 70, crit: 90),
                resetsAt: freshest.resetsAt,
                usedUSD: freshest.usedUSD,
                limitUSD: freshest.limitUSD)
        }
        fiveHour = limit("five_hour", label: "5h")
        sevenDay = limit("seven_day", label: "7d")
        spendLimit = limit("spend_limit", label: "$")
        // A week used evenly would stand here; nothing says how long a spend period is.
        if let resetsIn = sevenDay?.resetsIn {
            sevenDay?.evenMark = min(1, max(0, 1 - resetsIn / (7 * 86400)))
        }

        let live = newestFirst
            .filter { at - $0.updatedAt <= Summary.sessionWindow }
            .map { Summary.view(of: $0, at: at, state: states[$0.sessionID]) }
        var rest = live
        if let pinned, let index = live.firstIndex(where: { $0.id == pinned }) {
            current = rest.remove(at: index)
            isPinned = true
        } else if followsUrgent, let index = Summary.mostUrgent(live) {
            current = rest.remove(at: index)
            // The session that last did something is where the eye already is.
            isUrgent = index != 0
        } else if !rest.isEmpty {
            current = rest.removeFirst()
        }
        others = Array(rest.prefix(Summary.maxOthers))
        unlisted = Array(rest.dropFirst(Summary.maxOthers))
        isSubscription = snapshots.contains { $0.limits["five_hour"] != nil || $0.limits["seven_day"] != nil }
    }

    /// The session to look at first: of those about to lose a cache worth keeping, the one
    /// with the most to rewrite. Nil when none is.
    static func mostUrgent(_ sessions: [SessionView]) -> Int? {
        sessions.indices
            .filter { sessions[$0].advice.kind == .beforeExpiry }
            .max { sessions[$0].coldCost.tokens < sessions[$1].coldCost.tokens }
    }

    static func view(of snapshot: Snapshot, at: TimeInterval, state: SessionState? = nil) -> SessionView {
        // The plugin's note counts while something in the session still moves.
        let lastSign = max(snapshot.updatedAt, state?.at ?? 0)
        let isNoted = state != nil && at - lastSign <= runningGrace
        let lifetime = snapshot.cache.ttl ?? CacheState.lifetime
        // A read that kept the cache warm starts its lifetime over; the status line is not told of it.
        var expiresAt = snapshot.cache.expiresAt
        if let warm = state?.warm, warm.at + lifetime > (expiresAt ?? 0) {
            expiresAt = warm.at + lifetime
        }
        let cache: CacheState
        if snapshot.cache.active, at - snapshot.updatedAt <= activeGrace {
            cache = .active
        } else if isNoted, state?.state == SessionState.running {
            cache = .active
        } else if let expiresAt {
            cache = expiresAt > at ? .expires(in: expiresAt - at) : .expired
        } else {
            cache = .unknown
        }
        let folder = snapshot.cwd.map { URL(fileURLWithPath: $0).lastPathComponent } ?? ""
        let fallback = folder.isEmpty ? String(snapshot.sessionID.prefix(8)) : folder
        return SessionView(
            id: snapshot.sessionID,
            name: snapshot.name ?? fallback,
            source: snapshot.source,
            turnHit: snapshot.cache.turnHit,
            avgHit: snapshot.cache.avgHit,
            cache: cache,
            contextTokens: snapshot.context.tokens,
            contextWindow: snapshot.context.window,
            contextPercent: snapshot.context.percent,
            output: snapshot.context.output,
            costUSD: snapshot.costUSD,
            folder: fallback,
            lifetime: lifetime,
            lifetimeIsEstimate: snapshot.cache.ttl == nil || snapshot.source != "terminal",
            expiresAt: expiresAt,
            recacheTokens: snapshot.cache.recacheTokens,
            misses: snapshot.cache.misses ?? 0,
            missTokens: snapshot.cache.missRecacheTokens ?? 0,
            lastMissCauses: snapshot.cache.lastMissCauses ?? [],
            model: snapshot.model,
            modelID: snapshot.modelID,
            effort: snapshot.effort,
            isFast: snapshot.fast ?? false,
            worktree: snapshot.worktree,
            // Waiting stands until the session moves again, however long that takes.
            isWaiting: state?.state == SessionState.waiting && (state?.at ?? 0) >= snapshot.updatedAt - 5,
            isIdle: state?.state == SessionState.idle && cache != .active,
            acceptsCompact: state?.accepts?.contains(SessionRequest.compact) ?? false,
            lastCompact: state?.compact,
            compactFailed: state?.compactFailed,
            acceptsWarm: state?.accepts?.contains(SessionRequest.warm) ?? false,
            acceptsInstructions: state?.accepts?.contains(SessionRequest.instructions) ?? false,
            lastWarm: state?.warm,
            warmFailed: state?.warmFailed,
            idleCompactMin: state?.idleCompact?.minTokens)
    }

    /// Some session is waiting on the person.
    public var isAnyWaiting: Bool { every.contains(where: \.isWaiting) }

    /// The menu bar's own text: `5h 20%  7d 3%  ◷47:36`.
    public var title: [TitlePart] {
        var parts: [TitlePart] = []
        func add(_ part: TitlePart) {
            if !parts.isEmpty { parts.append(TitlePart("  ")) }
            parts.append(part)
        }
        for limit in [fiveHour, sevenDay].compactMap({ $0 }) {
            add(TitlePart("\(limit.label) \(limit.percent)%", limit.level == .ok ? .plain : limit.level))
        }
        if let current {
            add(TitlePart("◷\(current.cache.text)", current.cacheLevel))
        }
        return parts.isEmpty ? [TitlePart("◷--")] : parts
    }

    public var titleText: String { title.map(\.text).joined() }

    // MARK: As text

    /// Everything the popover shows, as lines of text, top to bottom; `nil` is a rule.
    /// What `--dump` prints.
    public func rows(_ strings: Strings, now: Date = Date()) -> [String?] {
        func limitRow(_ limit: LimitView?, title: String) -> String {
            guard let limit else { return "\(title)  \(strings.noReading)" }
            let reset = limit.resetsIn.map { "  ·  " + strings.reset(in: $0) } ?? ""
            let pace = limit.paceLine(strings, now: now).map { "  ·  " + $0 } ?? ""
            return "\(title)  \(limit.bar)  \(limit.percent)% \(strings.used)\(reset)\(pace)"
        }
        func cacheText(_ cache: CacheState) -> String {
            switch cache {
            case .unknown: return strings.cacheUnknown
            case .active: return strings.cacheActive
            case .expires(let left): return "\(Format.countdown(left)) \(strings.cacheExpiresCaption)"
            case .expired: return strings.cacheExpired
            }
        }
        func hit(_ value: Int?) -> String { value.map { "\($0)%" } ?? "--" }
        func cost(_ value: Double?) -> String { value.map { String(format: "$%.2f", $0) } ?? "--" }

        var rows: [String?] = showsSpendLimit
            ? [limitRow(spendLimit, title: strings.spendLimitTitle) + (spendLimit?.dollarsText.map { "  ·  " + $0 } ?? ""), nil]
            : [limitRow(fiveHour, title: strings.fiveHourTitle), limitRow(sevenDay, title: strings.sevenDayTitle), nil]
        if let current {
            var contextRow = "\(strings.context)  \(Format.tokens(current.contextTokens)) / \(Format.tokens(current.contextWindow))"
            if let percent = current.contextPercent { contextRow += " (\(Int(percent.rounded()))%)" }
            let advice = current.advice
            let label = isPinned ? strings.pinned : isUrgent ? strings.mostUrgent : strings.currentSession
            rows += ["\(strings.adviceTitle): \(advice.headline(strings))", advice.detail(strings)]
            // Lines that only some sessions have are left out, not printed empty.
            let costLines: [String] = [
                current.coldLine(strings), current.coldPriceLine(strings, isSubscription: isSubscription),
            ].compactMap { $0 }
            rows += costLines
            rows.append(nil)
            rows += [
                ([current.name, strings.source(current.source), label, current.subtitle]
                    + (current.isWaiting ? [strings.waitingForYou] : []))
                    .filter { !$0.isEmpty }.joined(separator: "  ·  "),
                cacheText(current.cache) + (current.cache == .unknown ? "" : "  ·  \(current.lifetimeLabel)"),
            ]
            let cacheLines: [String] = [
                current.shortCacheLine(strings, isSubscription: isSubscription), current.missLine(strings),
                current.missCauseLine(strings),
            ].compactMap { $0 }
            rows += cacheLines
            rows += [
                "\(strings.turnHit) \(hit(current.turnHit))  ·  \(strings.avgHit) \(hit(current.avgHit))  ·  \(isSubscription ? strings.costEquivalent : strings.cost) \(cost(current.costUSD))",
                contextRow,
            ]
            if let share = current.turnShareLine(strings) { rows.append(share) }
        } else {
            rows.append(strings.emptyTitle)
        }
        if !others.isEmpty {
            rows.append(nil)
            rows.append(strings.otherSessions)
            rows += others.map { session in
                "\(session.name)  ·  \(strings.source(session.source))   ❄\(session.coldCost.tokensText)   ◷\(session.cache.shortText)   \(cost(session.costUSD))"
                    + (session.isWaiting ? "   \(strings.waitingForYou)" : "")
                    + (session.resumeLine(strings).map { "   " + $0 } ?? "")
            }
        }
        return rows
    }
}
