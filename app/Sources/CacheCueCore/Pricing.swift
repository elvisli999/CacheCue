import Foundation

/// What Anthropic charges for cached tokens, relative to a model's base input price
/// (platform.claude.com/docs/en/about-claude/pricing, read 2026-10-13). The one copy of
/// these figures: the advice card and the guide both quote from here.
public enum Pricing {
    public struct Rate: Equatable {
        /// US dollars per million input tokens; nil for a model not in the table.
        public var base: Double?
        /// A cache read, as a multiple of the base price.
        public var read: Double
    }

    /// Writing to a one-hour cache costs twice the base price; to a five-minute cache, 1.25 times.
    public static func writeMultiplier(lifetime: TimeInterval) -> Double {
        lifetime >= 3600 ? 2 : 1.25
    }

    /// A cache read is a tenth of the base price on every model the table does not single out.
    public static let standardRead = 0.1

    /// Output costs five times the base input price on every model in the table.
    public static let outputMultiplier = 5.0

    private static let table: [(marker: String, base: Double, read: Double)] = [
        ("fable-5-1", 10, 0.025), ("mythos-5-1", 10, 0.025),
        ("fable-5", 10, 0.1), ("mythos-5", 10, 0.1),
        ("opus-5-5", 4, 0.05),
        ("opus-5", 5, 0.1), ("opus-4-8", 5, 0.1), ("opus-4-7", 5, 0.1), ("opus-4-6", 5, 0.1), ("opus-4-5", 5, 0.1),
        ("opus-4", 15, 0.1),
        ("sonnet-5-5", 2, 0.05),
        ("sonnet-5", 2, 0.1),
        ("sonnet-4", 3, 0.1),
        ("haiku-4-5", 1, 0.1),
        ("haiku-3-5", 0.8, 0.1),
    ]

    /// The rate for a model by its API name; the first marker the name contains decides,
    /// so the table lists `opus-5-5` before `opus-5`.
    public static func rate(modelID: String?, promptTokens: Double) -> Rate {
        guard let id = modelID?.lowercased() else { return Rate(base: nil, read: standardRead) }
        // Haiku 5.5 has two prices, by the size of the prompt.
        if id.contains("haiku-5-5") {
            return Rate(base: promptTokens > 100_000 ? 0.5 : 0.1, read: standardRead)
        }
        if let row = table.first(where: { id.contains($0.marker) }) {
            return Rate(base: row.base, read: row.read)
        }
        return Rate(base: nil, read: standardRead)
    }
}

/// What it costs a session to let its cache go cold: the next request writes the whole
/// prompt again where it would have read it.
public struct ColdCost: Equatable {
    public var tokens: Double
    /// The size is the context's, not Claude Code's own count of what would be rewritten.
    public var isEstimate: Bool
    /// The cold write's price over the warm read's.
    public var ratio: Double
    /// The model is not in the table, so the ratio is the least it can be.
    public var isFloor: Bool
    /// At list prices; nil for a model without a known price.
    public var coldUSD: Double?
    public var warmUSD: Double?

    public init(tokens: Double, isEstimate: Bool, modelID: String?, lifetime: TimeInterval) {
        let rate = Pricing.rate(modelID: modelID, promptTokens: tokens)
        let write = Pricing.writeMultiplier(lifetime: lifetime)
        self.tokens = tokens
        self.isEstimate = isEstimate
        ratio = write / rate.read
        isFloor = rate.base == nil
        coldUSD = rate.base.map { tokens * $0 * write / 1_000_000 }
        warmUSD = rate.base.map { tokens * $0 * rate.read / 1_000_000 }
    }

    /// `310.2k`, or `~310.2k` for an estimate.
    public var tokensText: String { (isEstimate ? "~" : "") + Format.tokens(tokens) }

    /// `40`, `12.5`, or `≥20` for a model whose read price is not known to be lower.
    public var ratioText: String {
        let number = ratio == ratio.rounded() ? String(Int(ratio)) : String(format: "%.1f", ratio)
        return (isFloor ? "≥" : "") + number
    }

    public static func dollars(_ value: Double) -> String {
        String(format: value < 10 ? "$%.2f" : "$%.1f", value)
    }
}

/// What each way of meeting a cache's expiry costs at list prices: coming back to it cold,
/// compacting it first, or keeping it warm another lifetime.
public struct ExpiryCosts: Equatable {
    /// What a compaction's summary is taken to run to, in tokens: the compaction figure is an
    /// estimate, the other two are not.
    public static let summaryTokens = 15_000.0

    /// The next request writes the whole prompt again.
    public var coldUSD: Double
    /// The summarising request reads the prompt and writes the summary; coming back writes the
    /// summary into the cache.
    public var compactUSD: Double
    /// One read of the prompt from the cache.
    public var warmUSD: Double

    /// Nil for a model without a known price.
    public init?(tokens: Double, modelID: String?, lifetime: TimeInterval) {
        let rate = Pricing.rate(modelID: modelID, promptTokens: tokens)
        guard let base = rate.base else { return nil }
        let perToken = base / 1_000_000
        let write = Pricing.writeMultiplier(lifetime: lifetime)
        let summary = min(ExpiryCosts.summaryTokens, tokens)
        coldUSD = tokens * perToken * write
        warmUSD = tokens * perToken * rate.read
        compactUSD = warmUSD + summary * perToken * (Pricing.outputMultiplier + write)
    }
}
