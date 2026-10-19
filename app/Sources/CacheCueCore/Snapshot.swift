import Foundation

/// One session's figures, as the status line command (terminal) or the cachecue plugin
/// (desktop) last wrote them to `~/Library/Caches/CacheCue/<session_id>.json`.
public struct Snapshot: Codable, Equatable {
    public struct Cache: Codable, Equatable {
        public var turnHit: Int?
        public var avgHit: Int?
        /// Epoch seconds.
        public var expiresAt: Double?
        /// A turn is in flight, so the cache is in use and the countdown is not running.
        public var active: Bool
        /// How long this session's cache entries live, in seconds: 300 or 3600. Nil when the
        /// writer was not told.
        public var ttl: Double? = nil
        /// Tokens the next request writes again if the cache has gone cold by then.
        public var recacheTokens: Double? = nil
        /// Requests that re-processed what the cache already held, and what they wrote again.
        public var misses: Int? = nil
        public var missRecacheTokens: Double? = nil
        /// Claude Code's names for what likely caused the last of them, such as `tools_changed`.
        public var lastMissCauses: [String]? = nil

        enum CodingKeys: String, CodingKey {
            case turnHit = "turn_hit"
            case avgHit = "avg_hit"
            case expiresAt = "expires_at"
            case active, ttl, misses
            case recacheTokens = "recache_tokens"
            case missRecacheTokens = "miss_recache_tokens"
            case lastMissCauses = "last_miss_causes"
        }
    }

    public struct Limit: Codable, Equatable {
        /// 0 to 100.
        public var used: Double
        /// Epoch seconds.
        public var resetsAt: Double?
        /// A gateway's spend limit may also say what was spent and what the limit is.
        public var usedUSD: Double? = nil
        public var limitUSD: Double? = nil
        /// `daily`, `weekly` or `monthly`.
        public var period: String? = nil

        enum CodingKeys: String, CodingKey {
            case used, period
            case resetsAt = "resets_at"
            case usedUSD = "used_usd"
            case limitUSD = "limit_usd"
        }
    }

    public struct Context: Codable, Equatable {
        public var tokens: Double
        public var output: Double
        public var window: Double
        public var percent: Double?
    }

    /// Fields have been added since version 1 and none taken away or changed, so the number
    /// stays: a menu bar app older than its plugin skips what it does not know and still
    /// reads the rest. A change to what an existing field means is what raises it.
    public static let version = 1

    public var v: Int
    public var source: String
    public var sessionID: String
    public var cwd: String?
    public var cache: Cache
    /// Keyed `five_hour` / `seven_day` / `spend_limit`; a window with no reading is absent.
    public var limits: [String: Limit]
    /// Epoch seconds when this session received `limits`; nil when it cannot say.
    public var limitsAt: Double?
    public var context: Context
    public var costUSD: Double?
    /// Epoch seconds of the session's last activity: writers rewrite only on a change.
    public var updatedAt: Double
    /// The session's own name (`/rename`, or the generated title), when it has one.
    public var name: String? = nil
    /// The model as Claude Code shows it (`Opus`) and as the API names it.
    public var model: String? = nil
    public var modelID: String? = nil
    public var effort: String? = nil
    public var fast: Bool? = nil
    public var worktree: String? = nil

    enum CodingKeys: String, CodingKey {
        case v, source, cwd, cache, limits, context, name, model, effort, fast, worktree
        case sessionID = "session_id"
        case limitsAt = "limits_at"
        case costUSD = "cost_usd"
        case updatedAt = "updated_at"
        case modelID = "model_id"
    }
}

/// What a session is doing, as the plugin last said beside the snapshot
/// (`<session_id>.state.json`): the status line command is never told.
public struct SessionState: Codable, Equatable {
    public static let running = "running"
    public static let waiting = "waiting"
    public static let idle = "idle"

    /// A compaction of the main conversation: its two sizes, in tokens.
    public struct Compaction: Codable, Equatable {
        /// Epoch seconds.
        public var at: Double
        public var before: Double?
        /// Nil until the session's next measure says how small it became.
        public var after: Double?
        /// `manual`, `auto`, or `plugin` for one this app asked for.
        public var trigger: String?
        /// The id of the request it answered, when the app asked for it.
        public var request: String?

        public init(at: Double, before: Double? = nil, after: Double? = nil, trigger: String? = nil, request: String? = nil) {
            self.at = at
            self.before = before
            self.after = after
            self.trigger = trigger
            self.request = request
        }
    }

    /// A compaction the app asked for that did not go through.
    public struct Failure: Codable, Equatable {
        public var at: Double
        public var request: String

        public init(at: Double, request: String) {
            self.at = at
            self.request = request
        }
    }

    /// A read of the cache the app asked for to keep it warm, which the cache served.
    public struct Warm: Codable, Equatable {
        /// Epoch seconds: the cache lives another lifetime from here.
        public var at: Double
        public var request: String
        /// Tokens the cache served.
        public var read: Double?
        /// Reads in a row since the main conversation last moved.
        public var count: Int

        public init(at: Double, request: String, read: Double? = nil, count: Int) {
            self.at = at
            self.request = request
            self.read = read
            self.count = count
        }
    }

    /// A keep-warm read that did not keep anything warm: `cold` when the cache had already
    /// gone, an API error's kind, or `unavailable` where Claude Code cannot make the read.
    public struct WarmFailure: Codable, Equatable {
        public var at: Double
        public var request: String
        public var reason: String?

        public init(at: Double, request: String, reason: String? = nil) {
            self.at = at
            self.request = request
            self.reason = reason
        }
    }

    /// Claude Code compacts this terminal session itself once it sits idle, at this size and above.
    public struct IdleCompact: Codable, Equatable {
        public var minTokens: Double

        public init(minTokens: Double) { self.minTokens = minTokens }

        enum CodingKeys: String, CodingKey {
            case minTokens = "min_tokens"
        }
    }

    public var sessionID: String
    public var state: String
    /// Epoch seconds.
    public var at: Double
    /// Main-conversation turns finished since the plugin loaded; it starts over on a reload.
    public var turns: Int? = nil
    /// What the plugin does when asked through a request file, such as `compact`.
    public var accepts: [String]? = nil
    public var compact: Compaction? = nil
    public var compactFailed: Failure? = nil
    public var warm: Warm? = nil
    public var warmFailed: WarmFailure? = nil
    public var idleCompact: IdleCompact? = nil

    public init(
        sessionID: String, state: String, at: Double, turns: Int? = nil, accepts: [String]? = nil,
        compact: Compaction? = nil, compactFailed: Failure? = nil, warm: Warm? = nil, warmFailed: WarmFailure? = nil,
        idleCompact: IdleCompact? = nil
    ) {
        self.sessionID = sessionID
        self.state = state
        self.at = at
        self.turns = turns
        self.accepts = accepts
        self.compact = compact
        self.compactFailed = compactFailed
        self.warm = warm
        self.warmFailed = warmFailed
        self.idleCompact = idleCompact
    }

    enum CodingKeys: String, CodingKey {
        case state, at, turns, accepts, compact, warm
        case sessionID = "session_id"
        case compactFailed = "compact_failed"
        case warmFailed = "warm_failed"
        case idleCompact = "idle_compact"
    }
}

/// Something the app asks of a session's plugin, left beside the snapshot
/// (`<session_id>.request.json`). The plugin reads it; only the app writes and removes it.
public struct SessionRequest: Codable, Equatable {
    public static let compact = "compact"
    /// Read the cache once, so that it lives another lifetime; nothing is added to the conversation.
    public static let warm = "warm"
    /// In a plugin's `accepts`: a compaction asked for may say what the summary should keep.
    public static let instructions = "instructions"

    public var v = 1
    public var sessionID: String
    public var action: String
    /// Tells one request from the next: the plugin acts on each once.
    public var id: String
    /// Epoch seconds.
    public var at: Double
    /// For a compaction: what the summary should keep.
    public var instructions: String? = nil

    public init(sessionID: String, action: String, id: String, at: Double, instructions: String? = nil) {
        self.sessionID = sessionID
        self.action = action
        self.id = id
        self.at = at
        self.instructions = instructions
    }

    enum CodingKeys: String, CodingKey {
        case v, action, id, at, instructions
        case sessionID = "session_id"
    }
}

public enum SnapshotStore {
    public static let retention: TimeInterval = 7 * 24 * 3600

    public static var defaultDirectory: URL {
        if let override = ProcessInfo.processInfo.environment["CACHECUE_DIR"], !override.isEmpty {
            return URL(fileURLWithPath: override, isDirectory: true)
        }
        return FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Caches/CacheCue", isDirectory: true)
    }

    private static func files(in directory: URL) -> [URL] {
        let found = try? FileManager.default.contentsOfDirectory(
            at: directory, includingPropertiesForKeys: [.contentModificationDateKey])
        return (found ?? []).filter { $0.pathExtension == "json" }
    }

    /// Every snapshot that decodes. A file caught mid-write, or of another version, is
    /// left out for this pass; the next pass reads it again.
    public static func load(from directory: URL) -> [Snapshot] {
        let decoder = JSONDecoder()
        return files(in: directory).compactMap { url in
            guard let data = try? Data(contentsOf: url),
                  let snapshot = try? decoder.decode(Snapshot.self, from: data),
                  snapshot.v == Snapshot.version
            else { return nil }
            return snapshot
        }
    }

    /// What each session was last said to be doing, by session id.
    public static func loadStates(from directory: URL) -> [String: SessionState] {
        let decoder = JSONDecoder()
        var states: [String: SessionState] = [:]
        for url in files(in: directory) where url.lastPathComponent.hasSuffix(".state.json") {
            guard let data = try? Data(contentsOf: url),
                  let state = try? decoder.decode(SessionState.self, from: data)
            else { continue }
            states[state.sessionID] = state
        }
        return states
    }

    private static let requestSuffix = ".request.json"

    public static func write(_ request: SessionRequest, in directory: URL) throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try JSONEncoder().encode(request)
            .write(to: directory.appendingPathComponent(request.sessionID + requestSuffix), options: .atomic)
    }

    /// Removes requests the plugin has answered (`answered` holds their ids) and those left
    /// unanswered for `life` seconds.
    public static func clearRequests(in directory: URL, answered: Set<String>, now: Date, life: TimeInterval) {
        let decoder = JSONDecoder()
        for url in files(in: directory) where url.lastPathComponent.hasSuffix(requestSuffix) {
            let request = (try? Data(contentsOf: url)).flatMap { try? decoder.decode(SessionRequest.self, from: $0) }
            if let request, !answered.contains(request.id), now.timeIntervalSince1970 - request.at <= life { continue }
            try? FileManager.default.removeItem(at: url)
        }
    }

    /// Removes snapshot files not touched for a week. Returns how many went.
    @discardableResult
    public static func prune(in directory: URL, now: Date) -> Int {
        var removed = 0
        for url in files(in: directory) {
            let modified = (try? url.resourceValues(forKeys: [.contentModificationDateKey]))?
                .contentModificationDate
            guard let modified, now.timeIntervalSince(modified) > retention else { continue }
            if (try? FileManager.default.removeItem(at: url)) != nil {
                removed += 1
            }
        }
        return removed
    }
}
