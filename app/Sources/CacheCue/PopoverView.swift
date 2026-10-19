import ServiceManagement
import SwiftUI
import CacheCueCore

// MARK: - Building blocks

/// Three capsules that fill left to right with `value` (0 to 1).
struct SegmentedProgressBar: View {
    let value: Double
    let tint: Color
    var segments = 3
    /// A tick across the bar at this share of its width: where even use would stand.
    var mark: Double?

    var body: some View {
        bar.overlay(
            GeometryReader { geometry in
                if let mark {
                    Capsule().fill(Color.primary.opacity(0.6))
                        .frame(width: 2, height: 9)
                        .position(x: geometry.size.width * CGFloat(mark), y: geometry.size.height / 2)
                }
            })
            // The figure beside every bar says the same in words.
            .accessibilityHidden(true)
    }

    private var bar: some View {
        HStack(spacing: 4) {
            ForEach(0..<segments, id: \.self) { index in
                GeometryReader { geometry in
                    let fill = min(max((value - Double(index) / Double(segments)) * Double(segments), 0), 1)
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.segmentBg)
                        Capsule()
                            .fill(LinearGradient(colors: [tint, tint.opacity(0.85)], startPoint: .leading, endPoint: .trailing))
                            .frame(width: geometry.size.width * CGFloat(fill))
                    }
                }
                .frame(height: 4)
            }
        }
    }
}

struct Card<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(.vertical, 12)
            .padding(.horizontal, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 14).fill(Color.cardBg))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.cardBorder, lineWidth: 1))
    }
}

struct IconBadge: View {
    let symbol: String
    var tint: Color = .brandAccent

    var body: some View {
        ZStack {
            Circle().fill(tint.opacity(0.1)).frame(width: 32, height: 32)
            Image(systemName: symbol).font(.system(size: 14, weight: .bold)).foregroundColor(tint)
        }
        .accessibilityHidden(true)
    }
}

/// A symbol that only decorates the words beside it: drawn, and not read out.
struct Glyph: View {
    let symbol: String
    var size: CGFloat = 9
    var weight: Font.Weight = .semibold

    var body: some View {
        Image(systemName: symbol).font(.system(size: size, weight: weight)).accessibilityHidden(true)
    }
}

extension EnvironmentValues {
    /// The off-screen render's stand-in for the system's "Differentiate without colour".
    var forcesLevelMarks: Bool {
        get { self[ForcesLevelMarksKey.self] }
        set { self[ForcesLevelMarksKey.self] = newValue }
    }
}

private struct ForcesLevelMarksKey: EnvironmentKey {
    static let defaultValue = false
}

extension Level {
    /// The shape that says this level where colour may not: a triangle warns, an octagon is worse.
    var markSymbol: String? {
        switch self {
        case .plain, .ok: return nil
        case .warn: return "exclamationmark.triangle.fill"
        case .crit: return "exclamationmark.octagon.fill"
        }
    }

    /// The cache's clock at this level. Its shape changes with it, so the level is not
    /// told by colour alone: an outline with a badge warns, a solid one is worse.
    var clockSymbol: String {
        switch self {
        case .plain, .ok: return "clock"
        case .warn: return "clock.badge.exclamationmark"
        case .crit: return "clock.badge.xmark.fill"
        }
    }
}

/// A level said by shape, before a figure that is otherwise only coloured by it. Shown to
/// someone who has asked the system not to rely on colour; nothing for anyone else.
struct LevelMark: View {
    let level: Level
    var size: CGFloat = 8
    @Environment(\.accessibilityDifferentiateWithoutColor) private var differentiates
    @Environment(\.forcesLevelMarks) private var isForced

    var body: some View {
        if differentiates || isForced, let symbol = level.markSymbol {
            Image(systemName: symbol).font(.system(size: size, weight: .bold)).foregroundColor(.tone(level))
                .accessibilityHidden(true)
        }
    }
}

struct Pill: View {
    let text: String
    var tint: Color = .secondaryText

    var body: some View {
        Text(text)
            .font(.rounded(9, .bold))
            .foregroundColor(tint)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(Capsule().fill(tint.opacity(0.09)))
    }
}

/// A headline number over a tiny caption.
struct Figure: View {
    let value: String
    let caption: String
    var tint: Color = .primary
    var size: CGFloat = 15
    /// The level the tint stands for, where it stands for one.
    var level = Level.plain

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                LevelMark(level: level, size: size * 0.55)
                Text(value).font(.rounded(size, .bold)).monospacedDigit().foregroundColor(tint)
            }
            Text(caption).font(.rounded(9, .medium)).foregroundColor(.secondaryText)
                .lineLimit(1).minimumScaleFactor(0.7)
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Cards

/// A small labelled switch. The off-screen render cannot draw a real one, so it gets one painted.
struct SwitchRow: View {
    let title: String
    @Binding var isOn: Bool
    var isPreview = false

    var body: some View {
        HStack(spacing: 8) {
            if isPreview {
                PaintedSwitch(isOn: isOn)
                Text(title).font(.rounded(11, .semibold)).lineLimit(1).minimumScaleFactor(0.8)
            } else {
                Toggle(isOn: $isOn) {
                    Text(title).font(.rounded(11, .semibold)).lineLimit(1).minimumScaleFactor(0.8)
                }
                .toggleStyle(.switch)
                .controlSize(.mini)
            }
            Spacer(minLength: 0)
        }
    }
}

/// A few options side by side, one chosen. Drawn rather than a system control, so the off-screen
/// render shows it as it looks.
struct ChoiceRow<Value: Hashable>: View {
    let title: String
    let options: [(value: Value, label: String)]
    @Binding var selection: Value

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title).font(.rounded(11, .semibold)).lineLimit(1).minimumScaleFactor(0.8)
            HStack(spacing: 2) {
                ForEach(options, id: \.value) { option in
                    let isChosen = option.value == selection
                    Button {
                        selection = option.value
                    } label: {
                        Text(option.label)
                            .font(.rounded(10, isChosen ? .bold : .medium)).lineLimit(1).minimumScaleFactor(0.7)
                            .foregroundColor(isChosen ? .brandAccent : .secondaryText)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 5)
                                    .fill(isChosen ? Color.brandAccent.opacity(0.12) : Color.clear))
                            .overlay(
                                RoundedRectangle(cornerRadius: 5)
                                    .strokeBorder(isChosen ? Color.brandAccent.opacity(0.6) : Color.clear, lineWidth: 1))
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(isChosen ? [.isSelected] : [])
                }
            }
            .padding(2)
            .background(RoundedRectangle(cornerRadius: 7).fill(Color.segmentBg))
            .accessibilityElement(children: .contain)
            .accessibilityLabel(title)
        }
    }
}

struct PaintedSwitch: View {
    let isOn: Bool

    var body: some View {
        ZStack(alignment: isOn ? .trailing : .leading) {
            Capsule().fill(isOn ? Color.brandAccent : Color.secondaryText.opacity(0.3)).frame(width: 26, height: 15)
            Circle().fill(Color.white).frame(width: 13, height: 13).padding(.horizontal, 1)
        }
    }
}

/// The app's reason for being: is now a good moment to run /compact, and why.
struct AdviceCard: View {
    let advice: CompactAdvice
    let strings: Strings
    /// What letting the cache go cold costs, in tokens and as a multiple; then in dollars.
    var coldLine: String?
    var priceLine: String?
    /// Opens the lesson that explains this advice; nil where there is none to open.
    var onWhy: (() -> Void)?
    @State private var didCopy = false

    private var tint: Color { .tone(advice.level, default: .brandAccent) }

    private var symbol: String {
        switch advice.kind {
        case .running: return "hourglass"
        case .notNeeded: return "checkmark"
        case .optional: return "arrow.triangle.branch"
        case .worthIt: return "flag.fill"
        case .beforeExpiry: return "figure.walk"
        case .cold: return "snowflake"
        case .nearFull: return "exclamationmark.triangle.fill"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 12) {
                IconBadge(symbol: symbol, tint: tint)
                VStack(alignment: .leading, spacing: 3) {
                    Text(strings.adviceTitle.uppercased()).font(.rounded(9, .bold)).foregroundColor(.secondaryText)
                        .accessibilityAddTraits(.isHeader)
                    Text(advice.headline(strings))
                        .font(.system(.subheadline, design: .rounded)).fontWeight(.bold)
                        .foregroundColor(advice.level == .plain || advice.level == .ok ? .primary : tint)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(advice.detail(strings))
                        .font(.rounded(10)).foregroundColor(.secondaryText).fixedSize(horizontal: false, vertical: true)
                    if let coldLine {
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Glyph(symbol: "snowflake", size: 8, weight: .bold)
                            Text(coldLine).font(.rounded(10, .semibold)).monospacedDigit()
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.top, 2)
                    }
                    if let priceLine {
                        Text(priceLine).font(.rounded(10)).monospacedDigit().foregroundColor(.secondaryText)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                Spacer(minLength: 0)
            }
            HStack(spacing: 8) {
            // The command, ready to paste, only when running it is the advice.
            if advice.kind != .running && advice.kind != .notNeeded {
                Button {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString("/compact", forType: .string)
                    didCopy = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { didCopy = false }
                } label: {
                    HStack(spacing: 4) {
                        Glyph(symbol: didCopy ? "checkmark" : "doc.on.doc")
                        Text(didCopy ? strings.copied : strings.copyCompact).font(.rounded(10, .semibold))
                    }
                    .foregroundColor(tint)
                    .padding(.horizontal, 9).padding(.vertical, 4)
                    .background(Capsule().fill(tint.opacity(0.09)))
                }
                .buttonStyle(.plain)
            }
            if let onWhy {
                Button(action: onWhy) {
                    HStack(spacing: 4) {
                        Glyph(symbol: "book")
                        Text(strings.why).font(.rounded(10, .semibold))
                    }
                    .foregroundColor(.secondaryText)
                    .padding(.horizontal, 9).padding(.vertical, 4)
                    .background(Capsule().fill(Color.secondaryText.opacity(0.10)))
                }
                .buttonStyle(.plain)
            }
            }
            .padding(.leading, 44)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(LinearGradient(colors: [tint.opacity(0.07), Color.cardBg], startPoint: .topLeading, endPoint: .bottomTrailing)))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(tint.opacity(0.28), lineWidth: 1))
    }
}

/// A newer release is out: says which, and hands over to the updater to install it.
struct UpdateCard: View {
    let version: String
    let strings: Strings
    let install: () -> Void

    var body: some View {
        Card {
            HStack(spacing: 10) {
                Image(systemName: "arrow.down.circle.fill").font(.system(size: 14)).foregroundColor(.brandAccent)
                    .accessibilityHidden(true)
                Text(String(format: strings.updateAvailable, version))
                    .font(.rounded(11, .semibold)).fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 4)
                Button(strings.download, action: install)
                    .buttonStyle(.plain).font(.rounded(11, .bold)).foregroundColor(.brandAccent)
                    .padding(.horizontal, 10).padding(.vertical, 4)
                    .background(Capsule().fill(Color.brandAccent.opacity(0.09)))
            }
        }
    }
}

/// The update card, watching the updater so it appears the moment a check finds something.
struct UpdateBanner: View {
    @ObservedObject var updater: Updater
    let strings: Strings

    var body: some View {
        if let version = updater.availableVersion {
            UpdateCard(version: version, strings: strings, install: updater.showUpdate)
        }
    }
}

/// The switch for Sparkle's scheduled checks.
struct UpdateSwitch: View {
    @ObservedObject var updater: Updater
    let strings: Strings

    var body: some View {
        Toggle(isOn: Binding(get: { updater.automaticallyChecks }, set: { updater.automaticallyChecks = $0 })) {
            Text(strings.checkUpdates).font(.rounded(11, .semibold)).lineLimit(1)
        }
        .toggleStyle(.switch)
        .controlSize(.mini)
    }
}

/// Shown until the terminal status line points at this app: one press sets it up.
struct SetupCard: View {
    let strings: Strings
    @Binding var state: StatusLineSetup.State
    /// Puts the card away for good: not everyone uses Claude Code in a terminal.
    let hide: () -> Void
    /// The off-screen render of a terminal connected with an earlier status line kept behind.
    var previewsKept = false
    @State private var isConfirming = false
    @State private var message: String?
    /// The status line that was there before, still run behind this app's command.
    @State private var kept = StatusLineSetup.chained()

    var body: some View {
        Group {
            if state != .ours || message != nil {
                connectCard
            } else if kept != nil || previewsKept {
                // Connected, with the person's own status line kept: the way back is here.
                Card {
                    HStack(spacing: 10) {
                        Glyph(symbol: "terminal.fill", size: 12).foregroundColor(.secondaryText)
                        Text(strings.setupKept).font(.rounded(11, .semibold)).fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: 0)
                        Button(strings.setupDisconnect, action: disconnect)
                            .buttonStyle(.plain).font(.rounded(11, .semibold)).foregroundColor(.secondaryText)
                    }
                }
            }
        }
        .onAppear { kept = StatusLineSetup.chained() }
    }

    /// Takes this app's command out of the status line setting; what was there before stands again.
    private func disconnect() {
        do {
            try StatusLineSetup.remove()
            message = strings.setupRestored
        } catch {
            message = String(format: strings.setupFailed, error.localizedDescription)
        }
        state = StatusLineSetup.state()
        kept = StatusLineSetup.chained()
    }

    private var connectCard: some View {
            Card {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 10) {
                        Glyph(symbol: "terminal.fill", size: 12).foregroundColor(.secondaryText)
                        Text(message ?? (isConfirming ? strings.setupReplace : strings.setupTitle))
                            .font(.rounded(11, .semibold)).fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: 0)
                        if state != .ours { HideButton(strings: strings, action: hide) }
                    }
                    if state != .ours {
                        HStack(spacing: 8) {
                            Spacer()
                            if isConfirming {
                                Button(strings.cancel) { isConfirming = false }
                                    .buttonStyle(.plain).font(.rounded(11, .semibold)).foregroundColor(.secondaryText)
                                Button(strings.setupReplaceButton) { setUp(keeping: false) }
                                    .buttonStyle(.plain).font(.rounded(11, .semibold)).foregroundColor(.secondaryText)
                                // Keeping the other status line is the choice that loses nothing.
                                Button(strings.setupKeep) { setUp(keeping: true) }
                                    .buttonStyle(.plain).font(.rounded(11, .bold)).foregroundColor(.brandAccent)
                                    .padding(.horizontal, 10).padding(.vertical, 4)
                                    .background(Capsule().fill(Color.brandAccent.opacity(0.09)))
                            } else {
                                Button(strings.setupButton) { setUp(keeping: false) }
                                    .buttonStyle(.plain).font(.rounded(11, .bold)).foregroundColor(.brandAccent)
                                    .padding(.horizontal, 10).padding(.vertical, 4)
                                    .background(Capsule().fill(Color.brandAccent.opacity(0.09)))
                            }
                        }
                    }
                }
            }
    }

    private func setUp(keeping: Bool) {
        // Someone else's status line is kept or replaced only on a second, deliberate press.
        var kept: String?
        if case .other(let command) = state {
            if !isConfirming {
                isConfirming = true
                return
            }
            kept = keeping ? command : nil
        }
        guard let executable = Bundle.main.executablePath else { return }
        do {
            try StatusLineSetup.install(executable: executable, keeping: kept)
            message = strings.setupDone
        } catch {
            message = String(format: strings.setupFailed, error.localizedDescription)
        }
        isConfirming = false
        state = StatusLineSetup.state()
        kept = StatusLineSetup.chained()
    }
}

/// The small cross that puts a setup card away.
struct HideButton: View {
    let strings: Strings
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "xmark").font(.system(size: 8, weight: .bold)).foregroundColor(.secondaryText)
                .padding(4).background(Circle().fill(Color.secondaryText.opacity(0.09)))
        }
        .buttonStyle(.plain)
        .help(strings.setupHide)
        .accessibilityLabel(strings.setupHide)
    }
}

/// Shown until the Claude desktop app has the plugin that feeds this app: one press installs
/// the copy that travels inside the app, with the Claude Code already on this Mac.
struct DesktopSetupCard: View {
    let strings: Strings
    @Binding var isInstalled: Bool
    /// The plugin inside this build; nil in the off-screen render.
    let bundled: URL?
    /// The Claude Code that will do the installing; nil when this Mac has none.
    let claude: URL?
    let hide: () -> Void
    @State private var isWorking = false
    @State private var message: String?

    var body: some View {
        if !isInstalled || message != nil {
            Card {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .top, spacing: 10) {
                        Glyph(symbol: "macwindow", size: 12).foregroundColor(.secondaryText)
                        Text(message ?? (isWorking ? strings.desktopSetupWorking : claude == nil ? strings.desktopSetupNoClaude : strings.desktopSetupTitle))
                            .font(.rounded(11, .semibold)).fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: 0)
                        if !isInstalled && !isWorking { HideButton(strings: strings, action: hide) }
                    }
                    if !isInstalled && claude != nil && !isWorking {
                        HStack(spacing: 8) {
                            Spacer()
                            Button(strings.setupButton, action: install)
                                .buttonStyle(.plain).font(.rounded(11, .bold)).foregroundColor(.brandAccent)
                                .padding(.horizontal, 10).padding(.vertical, 4)
                                .background(Capsule().fill(Color.brandAccent.opacity(0.09)))
                        }
                    }
                }
            }
        }
    }

    private func install() {
        guard let claude else { return }
        isWorking = true
        message = nil
        let (bundled, home) = (bundled, FileManager.default.homeDirectoryForCurrentUser)
        // Claude Code takes a moment; the popover stays live meanwhile.
        Task.detached {
            let failure: String?
            do {
                try PluginSetup.install(bundled: bundled, home: home, claude: claude)
                failure = nil
            } catch {
                failure = error.localizedDescription
            }
            await MainActor.run {
                isWorking = false
                isInstalled = PluginSetup.isInstalled(home: home)
                message = failure.map { String(format: strings.setupFailed, $0) }
                    ?? (isInstalled ? strings.desktopSetupDone : String(format: strings.setupFailed, "?"))
            }
        }
    }
}

/// One rate-limit window: how much is used and when it resets.
struct LimitCard: View {
    let title: String
    let symbol: String
    let limit: LimitView?
    let strings: Strings
    /// A session is reporting, yet no limit came with it: the account is not told one.
    var isNotReported = false
    /// Where the present rate of use leads, in words.
    var paceLine: String?
    /// Where the bar would stand under even use, 0 to 1.
    var mark: Double?

    var body: some View {
        Card {
            HStack(spacing: 12) {
                IconBadge(symbol: symbol)
                VStack(alignment: .leading, spacing: 5) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(title).font(.system(.subheadline, design: .rounded)).fontWeight(.bold)
                            .accessibilityAddTraits(.isHeader)
                        Spacer()
                        Text(limit?.resetsIn.map { strings.reset(in: $0) }
                            ?? (limit == nil && isNotReported ? strings.limitNotReported : strings.noReading))
                            .font(.system(.caption2, design: .rounded))
                            .foregroundColor(.secondaryText)
                    }
                    HStack(spacing: 8) {
                        SegmentedProgressBar(
                            value: (limit?.used ?? 0) / 100, tint: .toneFill(limit?.level ?? .plain, default: .secondaryText),
                            mark: mark)
                        Figure(value: limit.map { "\($0.percent)%" } ?? "--", caption: strings.used)
                            .frame(minWidth: 34)
                    }
                    if let dollars = limit?.dollarsText {
                        Text(dollars).font(.rounded(10, .semibold)).monospacedDigit().foregroundColor(.secondaryText)
                    }
                    if let paceLine {
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Glyph(symbol: "speedometer", size: 8)
                            Text(paceLine).font(.rounded(10, .medium)).monospacedDigit()
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .foregroundColor(limit?.pace == .lasts ? .secondaryText : .tone(.warn))
                    }
                }
            }
            // One window, one sentence: its name, when it resets, how much is used.
            .accessibilityElement(children: .combine)
        }
    }
}

/// The session that last did something: its cache, its context window, its cost.
struct SessionCard: View {
    let session: SessionView
    let strings: Strings
    /// On a subscription the dollars are a value at API prices, not what is billed.
    var isSubscription = false
    /// Set when the person chose this session; pressing it goes back to following the latest.
    var unpin: (() -> Void)?
    /// The session is in view because its cache is about to go cold.
    var isUrgent = false
    /// Opens the lesson on what breaks the cache.
    var onMiss: (() -> Void)?
    /// What to do as this session's cache is about to go cold; nil where nothing is offered.
    var beforeExpiry: Binding<BeforeExpiry>?
    var isPreview = false

    private var cacheTint: Color {
        switch session.cache {
        case .unknown: return .secondaryText
        case .active: return .tone(.ok)
        case .expires: return .tone(session.cacheLevel, default: .tone(.ok))
        case .expired: return .tone(.crit)
        }
    }

    /// The cache's level, which the clock beside the countdown shows by its shape too.
    private var cacheMark: Level {
        switch session.cache {
        case .unknown: return .plain
        case .active: return .ok
        case .expires: return session.cacheLevel
        case .expired: return .crit
        }
    }

    /// The same for the bar under the countdown, which is a fill and not a word.
    private var cacheFill: Color {
        switch session.cache {
        case .unknown: return .secondaryText
        case .active: return .toneFill(.ok)
        case .expires: return .toneFill(session.cacheLevel, default: .toneFill(.ok))
        case .expired: return .toneFill(.crit)
        }
    }

    /// Why this session is the one in view, then what tells it from the others.
    private var caption: String {
        let label = unpin != nil ? strings.pinned : isUrgent ? strings.mostUrgent : strings.currentSession
        return session.subtitle.isEmpty ? label : label + " · " + session.subtitle
    }

    private var cacheCaption: String {
        switch session.cache {
        case .unknown: return strings.cacheUnknown
        case .active: return strings.cacheActive
        case .expires: return strings.cacheExpiresCaption
        case .expired: return strings.cacheExpired
        }
    }

    private var cacheHeadline: String {
        switch session.cache {
        case .unknown: return "--:--"
        case .active: return "LIVE"
        case .expires(let left): return Format.countdown(left)
        case .expired: return "00:00"
        }
    }

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    IconBadge(symbol: session.source == "terminal" ? "terminal.fill" : "macwindow")
                    VStack(alignment: .leading, spacing: 2) {
                        Text(session.name)
                            .font(.system(.subheadline, design: .rounded)).fontWeight(.bold)
                            .lineLimit(1).truncationMode(.middle)
                            .accessibilityAddTraits(.isHeader)
                        Text(caption)
                            .font(.system(.caption2, design: .rounded)).foregroundColor(isUrgent && unpin == nil ? .tone(.warn) : .secondaryText)
                            .lineLimit(1).truncationMode(.tail)
                    }
                    Spacer()
                    if let unpin {
                        Button(action: unpin) {
                            HStack(spacing: 3) {
                                Glyph(symbol: "pin.slash.fill", size: 8, weight: .regular)
                                Text(strings.followLatest).font(.rounded(9, .bold)).lineLimit(1)
                            }
                            .foregroundColor(.tone(.warn))
                            .padding(.horizontal, 7).padding(.vertical, 3)
                            .background(Capsule().fill(Color.tone(.warn).opacity(0.09)))
                        }
                        .buttonStyle(.plain)
                    }
                    if session.isWaiting {
                        Pill(text: strings.waitingForYou, tint: .tone(.warn))
                    } else {
                        Pill(text: strings.source(session.source), tint: .brandAccent)
                    }
                }

                // Cache: its lifetime running down.
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Glyph(symbol: cacheMark == .warn || cacheMark == .crit ? cacheMark.clockSymbol : "clock.arrow.circlepath", size: 10)
                            .foregroundColor(cacheTint)
                        Text(cacheHeadline).font(.rounded(20, .bold)).monospacedDigit()
                            .foregroundColor(session.cache == .unknown ? .secondaryText : .primary)
                        Text(cacheCaption).font(.rounded(10, .medium)).foregroundColor(.secondaryText)
                            .lineLimit(1).minimumScaleFactor(0.7)
                        Spacer(minLength: 0)
                        // Five minutes or an hour: which clock this is.
                        if session.cache != .unknown {
                            Pill(text: session.lifetimeLabel, tint: session.lifetime < 3600 ? .tone(.warn) : .secondaryText)
                        }
                    }
                    // Read as one: the time left, what it is, which clock.
                    .accessibilityElement(children: .combine)
                    SegmentedProgressBar(value: session.cacheFraction, tint: cacheFill)
                    if let note = session.shortCacheLine(strings, isSubscription: isSubscription) {
                        Text(note).font(.rounded(10)).foregroundColor(.secondaryText).fixedSize(horizontal: false, vertical: true)
                    }
                }

                HStack(spacing: 0) {
                    Figure(
                        value: session.turnHit.map { "\($0)%" } ?? "--", caption: strings.turnHit,
                        tint: session.turnHit.map { .tone(Format.hitLevel($0)) } ?? .secondaryText,
                        level: session.turnHit.map(Format.hitLevel) ?? .plain)
                        .frame(maxWidth: .infinity)
                    Divider().frame(height: 22)
                    Figure(
                        value: session.avgHit.map { "\($0)%" } ?? "--", caption: strings.avgHit,
                        tint: session.avgHit.map { .tone(Format.hitLevel($0)) } ?? .secondaryText,
                        level: session.avgHit.map(Format.hitLevel) ?? .plain)
                        .frame(maxWidth: .infinity)
                    Divider().frame(height: 22)
                    Figure(value: session.costUSD.map { String(format: "$%.2f", $0) } ?? "--", caption: isSubscription ? strings.costEquivalent : strings.cost)
                        .frame(maxWidth: .infinity)
                }

                // Cache misses Claude Code counted, and what it thinks caused the last.
                if let missLine = session.missLine(strings) {
                    Button {
                        onMiss?()
                    } label: {
                        HStack(alignment: .top, spacing: 6) {
                            Glyph(symbol: "arrow.triangle.2.circlepath", weight: .bold)
                                .foregroundColor(.tone(.warn))
                            VStack(alignment: .leading, spacing: 1) {
                                Text(missLine).font(.rounded(10, .semibold)).monospacedDigit()
                                    .fixedSize(horizontal: false, vertical: true)
                                if let cause = session.missCauseLine(strings) {
                                    Text(cause).font(.rounded(10)).foregroundColor(.secondaryText)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                            Spacer(minLength: 0)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }

                // Context window.
                VStack(alignment: .leading, spacing: 5) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(strings.context).font(.rounded(10, .semibold)).foregroundColor(.secondaryText)
                        Spacer()
                        Text("\(Format.tokens(session.contextTokens)) / \(Format.tokens(session.contextWindow))")
                            .font(.rounded(10, .semibold)).monospacedDigit()
                        if let percent = session.contextPercent {
                            let level = Format.level(percent, warn: 60, crit: 85)
                            HStack(alignment: .firstTextBaseline, spacing: 2) {
                                LevelMark(level: level)
                                Text("\(Int(percent.rounded()))%").font(.rounded(10, .bold)).monospacedDigit()
                                    .foregroundColor(.tone(level))
                            }
                        }
                    }
                    .accessibilityElement(children: .combine)
                    SegmentedProgressBar(
                        value: (session.contextPercent ?? 0) / 100,
                        tint: .toneFill(Format.level(session.contextPercent ?? 0, warn: 60, crit: 85)))
                    // The bigger the context, the more of the limit each turn takes.
                    if let share = session.turnShareLine(strings) {
                        Text(share).font(.rounded(10)).monospacedDigit().foregroundColor(.secondaryText)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                if let beforeExpiry {
                    VStack(alignment: .leading, spacing: 5) {
                        ChoiceRow(
                            title: strings.beforeExpiry,
                            options: [
                                (.leave, strings.choiceLeave), (.warm, strings.choiceWarm), (.compact, strings.choiceCompact),
                            ],
                            selection: beforeExpiry)
                        if let costs = session.expiryCostLine(strings, isSubscription: isSubscription) {
                            Text(costs).font(.rounded(10)).monospacedDigit().foregroundColor(.secondaryText)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        if let line = session.beforeExpiryLine(strings, choice: beforeExpiry.wrappedValue, now: Date()) {
                            let status = AutoCompact.status(of: session, choice: beforeExpiry.wrappedValue)
                            let isTrouble = status == .needsPlugin || status == .failed || status == .warmFailed
                            Text(line)
                                .font(.rounded(10)).monospacedDigit()
                                .foregroundColor(isTrouble ? .tone(.warn) : .secondaryText)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
        }
    }
}

/// A session that is not the current one, on one line.
struct OtherSessionRow: View {
    let session: SessionView
    let strings: Strings

    var body: some View {
        let resume = session.resumeLine(strings)
        VStack(alignment: .leading, spacing: 1) {
            // Tight columns: the name is what tells the sessions apart, and it is cut last.
            HStack(spacing: 6) {
                // A raised hand where the session's icon is, while Claude Code waits on the person.
                Image(systemName: session.isWaiting ? "hand.raised.fill" : session.source == "terminal" ? "terminal.fill" : "macwindow")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(session.isWaiting ? .tone(.warn) : .secondaryText).frame(width: 14)
                    // The hand has something to say; the session's own icon does not.
                    .accessibilityLabel(strings.waitingForYou)
                    .accessibilityHidden(!session.isWaiting)
                Text(session.name).font(.rounded(11, .semibold)).lineLimit(1).truncationMode(.middle)
                    // The name takes the room before the gap does.
                    .layoutPriority(1)
                Spacer(minLength: 0)
                // What this session rewrites if its cache goes cold; a cold one says so below.
                if resume == nil, session.contextTokens >= CompactAdvice.smallContext {
                    HStack(spacing: 2) {
                        Glyph(symbol: "snowflake", size: 8)
                        Text(session.coldCost.tokensText).font(.rounded(10, .semibold)).monospacedDigit().lineLimit(1)
                    }
                    .fixedSize()
                    .foregroundColor(.secondaryText)
                }
                HStack(spacing: 3) {
                    Glyph(symbol: session.cacheLevel.clockSymbol)
                    Text(session.cache.shortText).font(.rounded(10, .semibold)).monospacedDigit()
                }
                .foregroundColor(.tone(session.cacheLevel, default: .secondaryText))
                .frame(minWidth: 44, alignment: .trailing)
                Text(session.costUSD.map { String(format: "$%.2f", $0) } ?? "--")
                    .font(.rounded(10, .semibold)).monospacedDigit().foregroundColor(.secondaryText)
                    .frame(minWidth: 42, alignment: .trailing)
            }
            // A cold session costs this much to take up again.
            if let resume {
                Text(resume).font(.rounded(10, .medium)).monospacedDigit().foregroundColor(.tone(.crit))
                    .lineLimit(1).minimumScaleFactor(0.7).padding(.leading, 20)
            }
        }
    }
}

/// The mark that support has answered: an envelope that keeps ringing out until it is pressed.
struct ReplyBeacon: View {
    let count: Int
    @State private var isPulsing = false
    /// Someone who asked the system for less motion gets the badge standing still.
    @Environment(\.accessibilityReduceMotion) private var reducesMotion

    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: "envelope.badge.fill").font(.system(size: 10, weight: .semibold))
                .rotationEffect(.degrees(isPulsing ? 9 : -9))
            // One reply needs no number.
            if count > 1 {
                Text("\(count)").font(.rounded(10, .bold)).monospacedDigit()
            }
        }
        .foregroundColor(.white)
        .padding(.horizontal, 6).padding(.vertical, 3)
        .background(Capsule().fill(Color.beacon))
        .background(
            // A ring that spreads from the badge and fades, over and over.
            Capsule().stroke(Color.beacon, lineWidth: 2)
                .scaleEffect(isPulsing ? 1.45 : 1)
                .opacity(isPulsing ? 0 : 0.8)
        )
        .scaleEffect(isPulsing ? 1.06 : 0.97)
        .onAppear {
            guard !reducesMotion else { return }
            withAnimation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true)) { isPulsing = true }
        }
    }
}

/// The week's ledger: what cold caches and unexpected rebuilds cost, from totals the app
/// keeps on this Mac. One line until it is opened.
struct LedgerCard: View {
    let week: Week
    let strings: Strings
    /// Opens a lesson by its id.
    let open: (String) -> Void
    @AppStorage("ledgerExpanded") private var isExpanded = false

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: 8) {
                Button {
                    isExpanded.toggle()
                } label: {
                    HStack(spacing: 8) {
                        Text(strings.ledgerTitle.uppercased()).font(.rounded(9, .bold)).foregroundColor(.secondaryText)
                        Spacer(minLength: 0)
                        bars.accessibilityHidden(true)
                        Glyph(symbol: isExpanded ? "chevron.up" : "chevron.down", size: 8, weight: .bold)
                            .foregroundColor(.secondaryText)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(.isHeader)
                if week.isEmpty {
                    Text(strings.ledgerEmpty).font(.rounded(10)).foregroundColor(.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    row("snowflake", week.coldLine(strings)) { open("cache-clock") }
                    if isExpanded {
                        row("arrow.triangle.2.circlepath", week.rebuildLine(strings)) { open("cache-breakers") }
                        if let compacts = week.compactLine(strings) {
                            row("arrow.down.right.and.arrow.up.left", compacts) { open("compact-cost") }
                        }
                        if let hit = week.hit {
                            HStack(spacing: 2) {
                                Text(strings.avgHit).font(.rounded(10, .semibold)).foregroundColor(.secondaryText)
                                Spacer()
                                LevelMark(level: Format.hitLevel(hit))
                                Text("\(hit)%").font(.rounded(10, .bold)).monospacedDigit()
                                    .foregroundColor(.tone(Format.hitLevel(hit)))
                            }
                            .accessibilityElement(children: .combine)
                        }
                        if !week.projects.isEmpty {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(strings.ledgerProjects).font(.rounded(10, .semibold)).foregroundColor(.secondaryText)
                                Text(week.projectsLine).font(.rounded(10)).monospacedDigit()
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                }
                if isExpanded {
                    Text(strings.ledgerPrivacy).font(.rounded(9)).foregroundColor(.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    /// Seven days of tokens written again, today last.
    private var bars: some View {
        let peak = max(week.daily.max() ?? 0, 1)
        return HStack(alignment: .bottom, spacing: 2) {
            ForEach(Array(week.daily.enumerated()), id: \.offset) { _, tokens in
                Capsule()
                    .fill(tokens > 0 ? Color.toneFill(.warn) : Color.segmentBg)
                    .frame(width: 4, height: max(2, 14 * CGFloat(tokens / peak)))
            }
        }
        .frame(height: 14, alignment: .bottom)
    }

    private func row(_ symbol: String, _ text: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Glyph(symbol: symbol, weight: .bold).foregroundColor(.secondaryText)
                Text(text).font(.rounded(10, .semibold)).monospacedDigit().fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - The guide

/// The list of lessons, with the ones already read ticked.
struct GuideList: View {
    let lessons: [Lesson]
    let read: Set<String>
    let open: (String) -> Void

    var body: some View {
        VStack(spacing: 8) {
            ForEach(Array(lessons.enumerated()), id: \.element.id) { index, lesson in
                Button {
                    open(lesson.id)
                } label: {
                    Card {
                        HStack(alignment: .top, spacing: 12) {
                            ZStack {
                                Circle().fill(Color.brandAccent.opacity(read.contains(lesson.id) ? 0.10 : 0.16))
                                    .frame(width: 26, height: 26)
                                if read.contains(lesson.id) {
                                    Image(systemName: "checkmark").font(.system(size: 11, weight: .bold))
                                        .foregroundColor(.brandAccent)
                                } else {
                                    Text("\(index + 1)").font(.rounded(12, .bold)).foregroundColor(.brandAccent)
                                }
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text(lesson.title).font(.rounded(12, .bold)).foregroundColor(.primary)
                                    .multilineTextAlignment(.leading).fixedSize(horizontal: false, vertical: true)
                                Text(lesson.summary).font(.rounded(10)).foregroundColor(.secondaryText)
                                    .multilineTextAlignment(.leading).fixedSize(horizontal: false, vertical: true)
                            }
                            Spacer(minLength: 0)
                            Glyph(symbol: "chevron.forward").foregroundColor(.secondaryText).padding(.top, 8)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(12)
    }
}

/// One lesson: its points, the takeaway, where it comes from, and the way on.
struct LessonPage: View {
    let lesson: Lesson
    let number: Int
    let count: Int
    let strings: Strings
    /// The off-screen render cannot draw a link, so it gets the label alone.
    var isPreview = false
    /// Steps to the lesson before (-1) or after (+1).
    let step: (Int) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text("\(number) / \(count)").font(.rounded(10, .bold)).foregroundColor(.brandAccent)
                Text(lesson.title).font(.system(.title3, design: .rounded)).fontWeight(.bold)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
            }
            VStack(alignment: .leading, spacing: 9) {
                ForEach(Array(lesson.points.enumerated()), id: \.offset) { _, point in
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Circle().fill(Color.brandAccent.opacity(0.6)).frame(width: 4, height: 4)
                            .alignmentGuide(.firstTextBaseline) { $0[.bottom] + 3 }
                        Text(point).font(.rounded(11)).lineSpacing(2).fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(strings.takeaway.uppercased()).font(.rounded(9, .bold)).foregroundColor(.tone(.ok))
                Text(lesson.takeaway).font(.rounded(12, .bold)).fixedSize(horizontal: false, vertical: true)
            }
            .padding(.vertical, 10).padding(.horizontal, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 12).fill(Color.tone(.ok).opacity(0.10)))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.tone(.ok).opacity(0.25), lineWidth: 1))

            HStack(spacing: 8) {
                if isPreview {
                    sourceLabel.foregroundColor(.brandAccent)
                } else {
                    Link(destination: lesson.source) { sourceLabel }
                }
                Spacer(minLength: 8)
                if number > 1 {
                    navigation(strings.previous, symbol: "chevron.backward", leading: true) { step(-1) }
                }
                if number < count {
                    navigation(strings.next, symbol: "chevron.forward", leading: false) { step(1) }
                }
            }
        }
        .padding(16)
    }

    private var sourceLabel: some View {
        HStack(spacing: 4) {
            Glyph(symbol: "arrow.up.forward.square", size: 10)
            Text(strings.readDocs).font(.rounded(10, .semibold)).lineLimit(1)
        }
    }

    private func navigation(_ title: String, symbol: String, leading: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if leading { Glyph(symbol: symbol, weight: .bold) }
                Text(title).font(.rounded(11, .bold)).lineLimit(1)
                if !leading { Glyph(symbol: symbol, weight: .bold) }
            }
            .foregroundColor(.brandAccent)
            .padding(.horizontal, 10).padding(.vertical, 5)
            .background(Capsule().fill(Color.brandAccent.opacity(0.09)))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - The popover

/// What the popover is showing: the figures, the guide's list, or one lesson.
enum Page: Equatable {
    case dashboard
    case guide
    case lesson(String)
    case about
    case settings
}

/// What the app is, which version, and where its maker and its source are. The links leave
/// the first page to the figures.
struct AboutPage: View {
    let strings: Strings
    var updater: Updater?
    /// Opens the support pages, the only way into them; nil where there are none.
    var openSupport: (() -> Void)?
    /// Replies from support not opened yet: the row says so and leads to them.
    var unreadReplies = 0

    var body: some View {
        VStack(spacing: 10) {
            Card {
                VStack(spacing: 8) {
                    BrandMark(size: 44)
                    VStack(spacing: 2) {
                        Text("CacheCue").font(.system(.title3, design: .rounded)).fontWeight(.bold)
                            .accessibilityAddTraits(.isHeader)
                        Text(Preferences.versionLabel).font(.rounded(11, .semibold)).monospacedDigit().foregroundColor(.secondaryText)
                    }
                    Text(strings.aboutTagline).font(.rounded(11)).foregroundColor(.secondaryText)
                        .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
                    // Checks there and then; a build that is no release has nothing to check against.
                    Button {
                        updater?.showUpdate()
                    } label: {
                        Text(strings.aboutCheckNow).font(.rounded(11, .bold)).foregroundColor(.brandAccent)
                            .padding(.horizontal, 10).padding(.vertical, 4)
                            .background(Capsule().fill(Color.brandAccent.opacity(0.09)))
                    }
                    .buttonStyle(.plain)
                    .disabled(updater?.canCheck != true)
                    .opacity(updater?.canCheck == true ? 1 : 0.45)
                }
                .frame(maxWidth: .infinity)
            }
            Card {
                VStack(spacing: 0) {
                    link("globe", strings.aboutWebsite, detail: "elvisli.ca/cachecue") { NSWorkspace.shared.open(SupportAPI.websiteURL) }
                    Divider().padding(.vertical, 8)
                    link("chevron.left.forwardslash.chevron.right", strings.aboutSource, detail: "github.com/elvisli999/CacheCue") {
                        NSWorkspace.shared.open(SupportAPI.sourceURL)
                    }
                    if let openSupport {
                        Divider().padding(.vertical, 8)
                        link(
                            "lifepreserver", strings.support, detail: unreadReplies > 0 ? strings.supportNewReply : nil,
                            leaves: false, badge: unreadReplies, action: openSupport)
                    }
                    Divider().padding(.vertical, 8)
                    // The app is free; this only hands the tip page to the browser.
                    link("cup.and.saucer.fill", strings.buyCoffee, detail: "ko-fi.com/elvislica", tint: .tone(.warn)) {
                        NSWorkspace.shared.open(SupportAPI.coffeeURL)
                    }
                }
            }
            Text(strings.aboutNotAffiliated + " MIT License.").font(.rounded(10)).foregroundColor(.secondaryText)
                .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 8)
        }
        .padding(12)
    }

    /// One way out of the app, or into another of its pages: `leaves` says which.
    private func link(
        _ symbol: String, _ title: String, detail: String?, tint: Color = .brandAccent, leaves: Bool = true,
        badge: Int = 0, action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Glyph(symbol: symbol, size: 12).foregroundColor(tint).frame(width: 18)
                VStack(alignment: .leading, spacing: 1) {
                    Text(title).font(.rounded(11, .semibold)).lineLimit(1).minimumScaleFactor(0.8)
                    if let detail {
                        Text(detail).font(.rounded(10)).foregroundColor(.secondaryText).lineLimit(1).truncationMode(.middle)
                    }
                }
                Spacer(minLength: 8)
                if badge > 0 {
                    ReplyBeacon(count: badge).accessibilityHidden(true)
                }
                Glyph(symbol: leaves ? "arrow.up.right" : "chevron.forward", weight: .bold).foregroundColor(.secondaryText)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

struct PopoverView: View {
    let summary: Summary
    /// The last seven days of what the cache cost.
    var week = Week()
    /// The off-screen render cannot draw native controls, so it gets a painted footer.
    var isPreview = false
    /// The render's language; the app reads the person's choice from its defaults.
    var previewLanguage: Language?
    var initialPage = Page.dashboard
    /// Sparkle, in a release build; nil in the off-screen render.
    var updater: Updater?
    /// Keeps a session in view by its id; nil goes back to following the latest.
    var pin: (String?) -> Void = { _ in }
    /// What the person chose for each session's cache before it goes cold, and the way to change that.
    var choices: [String: BeforeExpiry] = [:]
    var setChoice: (String, BeforeExpiry) -> Void = { _, _ in }
    /// The support pages' state, which outlives the popover.
    var support: SupportModel?
    /// Whether the support pages are showing; mirrors `support.isPresented`.
    var isShowingSupport = false
    /// How many tickets have a reply from support not opened yet; mirrors `support.unread`.
    var unreadReplies = 0

    @State private var page: Page?
    /// Lesson ids already opened, comma-separated.
    @AppStorage("readLessons") private var readLessons = ""

    @AppStorage(Preferences.themeKey) private var themeChoice = AppTheme.system.rawValue
    @AppStorage(Preferences.languageKey) private var languageChoice = Language.system
    @State private var launchesAtLogin = SMAppService.mainApp.status == .enabled
    @State private var loginError: String?

    /// The off-screen render of a Mac where nothing is set up yet.
    var previewsSetup = false
    /// The off-screen render of a terminal connected with an earlier status line kept.
    var previewsKept = false
    @State private var terminalSetup = StatusLineSetup.state()
    @State private var hasDesktopPlugin = PluginSetup.isInstalled(home: FileManager.default.homeDirectoryForCurrentUser)
    @AppStorage("hideTerminalSetup") private var hidesTerminalSetup = false
    @AppStorage("hideDesktopSetup") private var hidesDesktopSetup = false

    @AppStorage(Preferences.followUrgentKey) private var followsUrgent = true
    @AppStorage(Preferences.alertCacheKey) private var alertsOnCache = false
    @AppStorage(Preferences.alertQuotaKey) private var alertsOnQuota = false
    @AppStorage(Preferences.alertLeadKey) private var alertLeadMinutes = Int(Alerts.defaultLead / 60)
    @AppStorage(Preferences.waitingMarkKey) private var marksWaiting = true
    @AppStorage(Preferences.compactInstructionsKey) private var compactInstructions = Preferences.defaultCompactInstructions
    /// macOS refused the notifications an alert needs.
    @State private var notificationsDenied = false

    /// Neither moves while the app runs; the popover redraws every second.
    private static let bundledPlugin = PluginSetup.bundled(resources: Bundle.main.resourceURL)
    @State private var claude = PluginSetup.claudeExecutable(home: FileManager.default.homeDirectoryForCurrentUser)
    private var bundledPlugin: URL? { Self.bundledPlugin }
    private var showsTerminalSetup: Bool { previewsSetup || previewsKept || (!isPreview && !hidesTerminalSetup) }
    /// A build that carries no plugin has nothing to offer here.
    private var showsDesktopSetup: Bool { previewsSetup || (!isPreview && !hidesDesktopSetup && bundledPlugin != nil) }
    /// Nothing feeds the app yet, and the cards that would fix it are still on screen.
    private var isUnconnected: Bool {
        if previewsSetup { return true }
        return terminalSetup != .ours && !hasDesktopPlugin
            && ((showsTerminalSetup) || (showsDesktopSetup))
    }

    private var language: Language { previewLanguage ?? Language.resolve(choice: languageChoice) }
    private var strings: Strings { .of(language) }
    private var theme: AppTheme { .stored(themeChoice) }
    private var sessionCount: Int { (summary.current == nil ? 0 : 1) + summary.others.count }
    private var shown: Page { page ?? initialPage }
    private var isLesson: Bool {
        if case .lesson = shown { return true }
        return false
    }
    /// Limits arrive with a session's first response; before that their absence says nothing.
    private var hasAnsweredSession: Bool { (summary.current?.contextTokens ?? 0) > 0 }
    private var lessons: [Lesson] { Guide.lessons(language) }
    private var read: Set<String> { Set(readLessons.split(separator: ",").map(String.init)) }

    /// Lessons read out of lessons there are, as the header's button shows it.
    private var guideProgress: String { "\(read.intersection(lessons.map(\.id)).count)/\(lessons.count)" }

    private func open(_ id: String) {
        readLessons = read.union([id]).sorted().joined(separator: ",")
        page = .lesson(id)
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            if let support, isShowingSupport {
                SupportView(model: support, strings: strings, isPreview: isPreview)
            } else {
            switch shown {
            case .dashboard:
                if isPreview {
                    dashboard
                } else {
                    // Taller than the screen allows, the cards scroll and the footer stays put.
                    ScrollView { dashboard }
                        .frame(maxHeight: Self.dashboardLimit)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Divider()
                footer
            case .guide:
                GuideList(lessons: lessons, read: read, open: open)
            case .lesson(let id):
                if let index = lessons.firstIndex(where: { $0.id == id }) {
                    LessonPage(
                        lesson: lessons[index], number: index + 1, count: lessons.count, strings: strings,
                        isPreview: isPreview
                    ) { by in
                        open(lessons[index + by].id)
                    }
                }
            case .about:
                // Leaving support comes back here, where it was entered.
                AboutPage(
                    strings: strings, updater: updater,
                    openSupport: support.map { support in
                        { if unreadReplies > 0 { support.showUnread() } else { support.isPresented = true } }
                    },
                    unreadReplies: unreadReplies)
            case .settings:
                settings
            }
            }
        }
        .frame(width: 320)
        .tint(.brandAccent)
        .environment(\.layoutDirection, language.isRightToLeft ? .rightToLeft : .leftToRight)
    }

    /// What the screen leaves for the cards, under the menu bar and above the footer.
    private static var dashboardLimit: CGFloat {
        max(360, (NSScreen.main?.visibleFrame.height ?? 900) - 170)
    }

    private var dashboard: some View {
        VStack(spacing: 10) {
            if let updater {
                UpdateBanner(updater: updater, strings: strings)
            }
            if let current = summary.current {
                AdviceCard(
                    advice: current.advice, strings: strings,
                    coldLine: current.coldLine(strings),
                    priceLine: current.coldPriceLine(strings, isSubscription: summary.isSubscription),
                    onWhy: Guide.lessonID(for: current.advice.kind).map { id in { open(id) } })
            }
            if summary.showsSpendLimit {
                // A gateway's spend limit stands in for the two windows a subscription has.
                LimitCard(
                    title: strings.spendLimitTitle, symbol: "dollarsign.circle.fill", limit: summary.spendLimit,
                    strings: strings)
            } else {
                LimitCard(
                    title: strings.fiveHourTitle, symbol: "bolt.fill", limit: summary.fiveHour, strings: strings,
                    isNotReported: hasAnsweredSession, paceLine: summary.fiveHour?.paceLine(strings, now: Date()))
                LimitCard(
                    title: strings.sevenDayTitle, symbol: "calendar", limit: summary.sevenDay, strings: strings,
                    isNotReported: hasAnsweredSession, paceLine: summary.sevenDay?.paceLine(strings, now: Date()),
                    mark: summary.sevenDay?.evenMark)
            }
            if let current = summary.current {
                SessionCard(
                    session: current, strings: strings, isSubscription: summary.isSubscription,
                    unpin: summary.isPinned ? { pin(nil) } : nil, isUrgent: summary.isUrgent,
                    onMiss: { open("cache-breakers") },
                    beforeExpiry: AutoCompact.isOffered(for: current)
                        ? Binding(get: { choices[current.id] ?? .leave }, set: { setChoice(current.id, $0) })
                        : nil,
                    isPreview: isPreview)
            } else {
                emptyState
            }
            if !summary.others.isEmpty {
                Card {
                    VStack(alignment: .leading, spacing: 9) {
                        Text(strings.otherSessions).font(.rounded(10, .semibold)).foregroundColor(.secondaryText)
                            .accessibilityAddTraits(.isHeader)
                        // Pressing a session keeps it in view.
                        ForEach(summary.others, id: \.id) { session in
                            Button {
                                pin(session.id)
                            } label: {
                                OtherSessionRow(session: session, strings: strings).contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .accessibilityElement(children: .combine)
                        }
                    }
                }
            }
            if summary.current != nil {
                LedgerCard(week: week, strings: strings, open: open)
            }
            if showsTerminalSetup {
                SetupCard(
                    strings: strings,
                    state: previewsSetup ? .constant(.notConfigured) : previewsKept ? .constant(.ours) : $terminalSetup,
                    hide: { hidesTerminalSetup = true }, previewsKept: previewsKept)
            }
            if showsDesktopSetup {
                DesktopSetupCard(
                    strings: strings, isInstalled: previewsSetup ? .constant(false) : $hasDesktopPlugin,
                    bundled: bundledPlugin,
                    claude: previewsSetup ? URL(fileURLWithPath: "/usr/bin/true") : claude,
                    hide: { hidesDesktopSetup = true })
            }
        }
        .padding(12)
        .onAppear {
            // Either may have been set up elsewhere since the popover was last open.
            terminalSetup = StatusLineSetup.state()
            hasDesktopPlugin = PluginSetup.isInstalled(home: FileManager.default.homeDirectoryForCurrentUser)
            claude = PluginSetup.claudeExecutable(home: FileManager.default.homeDirectoryForCurrentUser)
        }
    }

    private var header: some View {
        HStack(spacing: 10) {
            BrandMark()
            if isShowingSupport {
                Text(strings.support).font(.system(.headline, design: .rounded)).lineLimit(1)
                    .accessibilityAddTraits(.isHeader)
                Spacer()
                // No Esc here: the pages have fields, and an input method cancels with it.
                Button {
                    support?.isPresented = false
                } label: {
                    HStack(spacing: 3) {
                        Glyph(symbol: "chevron.backward", weight: .bold)
                        Text(strings.back).font(.rounded(11, .semibold))
                    }
                    .foregroundColor(.secondaryText)
                }
                .buttonStyle(.plain)
            } else if shown == .dashboard {
                Text("CacheCue").font(.system(.headline, design: .rounded))
                    .accessibilityAddTraits(.isHeader)
                Spacer()
                Pill(
                    text: sessionCount == 0 ? strings.idle : String(format: strings.activeCount, sessionCount),
                    tint: sessionCount == 0 ? .secondaryText : .brandAccent)
                Button {
                    page = .guide
                } label: {
                    HStack(spacing: 3) {
                        Glyph(symbol: "book.fill", size: 10, weight: .regular)
                        Text(guideProgress).font(.rounded(10, .bold)).monospacedDigit()
                    }
                    .foregroundColor(.brandAccent)
                    .padding(.horizontal, 7).padding(.vertical, 3)
                    .background(Capsule().fill(Color.brandAccent.opacity(0.09)))
                }
                .buttonStyle(.plain)
                .help(strings.guideTitle)
                .accessibilityLabel(strings.guideTitle)
                .accessibilityValue(guideProgress)
                // The way into support is on the About page. A reply is news, though, and
                // shows here until it is opened.
                if let support, unreadReplies > 0 {
                    Button {
                        support.showUnread()
                    } label: {
                        ReplyBeacon(count: unreadReplies)
                    }
                    .buttonStyle(.plain)
                    .help(strings.supportNewReply)
                    .accessibilityLabel(strings.supportNewReply)
                }
            } else {
                Text(shown == .about ? strings.about : shown == .settings ? strings.settings : strings.guideTitle)
                    .font(.system(.headline, design: .rounded)).lineLimit(1).minimumScaleFactor(0.8)
                    .accessibilityAddTraits(.isHeader)
                Spacer()
                Button {
                    // From a lesson back to the list; from the list, About or the settings, back to the figures.
                    page = isLesson ? .guide : .dashboard
                } label: {
                    HStack(spacing: 3) {
                        Glyph(symbol: "chevron.backward", weight: .bold)
                        Text(strings.back).font(.rounded(11, .semibold))
                    }
                    .foregroundColor(.secondaryText)
                }
                .buttonStyle(.plain)
                // Esc goes back a page.
                .keyboardShortcut(.cancelAction)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    private var emptyState: some View {
        Card {
            HStack(spacing: 12) {
                // Until something feeds the app, "send a message" would be a false promise.
                IconBadge(symbol: isUnconnected ? "link.badge.plus" : "moon.zzz.fill", tint: isUnconnected ? .tone(.warn) : .secondaryText)
                VStack(alignment: .leading, spacing: 3) {
                    Text(isUnconnected ? strings.connectTitle : strings.emptyTitle).font(.system(.subheadline, design: .rounded)).fontWeight(.bold)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(isUnconnected ? strings.connectHint : strings.emptyHint)
                        .font(.rounded(10)).foregroundColor(.secondaryText).fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    // MARK: Footer

    /// One line: the way to the settings, the way to the About page, and the way out.
    private var footer: some View {
        HStack(spacing: 12) {
            Button {
                page = .settings
            } label: {
                HStack(spacing: 4) {
                    Glyph(symbol: "gearshape.fill", size: 11)
                    Text(strings.settings).font(.rounded(11, .semibold)).lineLimit(1)
                }
                .foregroundColor(.secondaryText)
            }
            .buttonStyle(.plain)
            // Where every Mac app keeps its settings.
            .keyboardShortcut(",", modifiers: .command)
            Spacer(minLength: 8)
            // The version, the links, the check for an update.
            Button {
                page = .about
            } label: {
                HStack(spacing: 4) {
                    Glyph(symbol: "info.circle", size: 11)
                    Text(strings.about).font(.rounded(11, .semibold)).lineLimit(1)
                    Text(Preferences.versionLabel).font(.rounded(10, .semibold)).monospacedDigit()
                }
                .foregroundColor(.secondaryText)
            }
            .buttonStyle(.plain)
            Button {
                NSApplication.shared.terminate(nil)
            } label: {
                HStack(spacing: 3) {
                    Glyph(symbol: "xmark.circle.fill", size: 13, weight: .regular)
                    Text(strings.quit).font(.rounded(11, .semibold)).lineLimit(1)
                }
                .foregroundColor(.secondaryText)
            }
            .buttonStyle(.plain)
            .keyboardShortcut("q", modifiers: .command)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.primary.opacity(0.015))
    }

    // MARK: Settings

    /// Every switch and choice that is the app's, not one session's, in three groups.
    private var settings: some View {
        VStack(spacing: 10) {
            settingsGroup(strings.settingsGeneral) {
                footerSwitch(strings.launchAtLogin, isOn: Binding(get: { launchesAtLogin }, set: setLaunchAtLogin))
                if let loginError {
                    Text(loginError).font(.rounded(10)).foregroundColor(.tone(.crit)).fixedSize(horizontal: false, vertical: true)
                }
                settingsRow(strings.language) {
                    if isPreview {
                        languageLabel
                    } else {
                        Menu {
                            languageButton(Language.system, title: strings.followSystem)
                            Divider()
                            ForEach(Language.allCases) { language in
                                languageButton(language.rawValue, title: language.nativeName)
                            }
                        } label: {
                            languageLabel
                        }
                        .menuStyle(.borderlessButton)
                        .menuIndicator(.hidden)
                        .fixedSize()
                        .accessibilityLabel(strings.language)
                        .accessibilityValue(languageName)
                    }
                }
                settingsRow(strings.appearance) {
                    // Steps through system, light and dark.
                    Button {
                        let next = theme.next
                        themeChoice = next.rawValue
                        next.apply()
                    } label: {
                        HStack(spacing: 4) {
                            Glyph(symbol: theme.symbol, size: 12, weight: .regular)
                            Text(theme.label(strings)).font(.rounded(11, .semibold)).lineLimit(1)
                        }
                        .foregroundColor(.secondaryText)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(strings.appearance)
                    .accessibilityValue(theme.label(strings))
                }
                if isPreview {
                    SwitchRow(title: strings.checkUpdates, isOn: .constant(true), isPreview: true)
                } else if let updater, updater.canCheck {
                    HStack(spacing: 8) {
                        UpdateSwitch(updater: updater, strings: strings)
                        Spacer(minLength: 0)
                    }
                }
            }
            settingsGroup(strings.settingsSessions) {
                footerSwitch(strings.followUrgent, isOn: $followsUrgent)
                footerSwitch(strings.waitingMark, isOn: $marksWaiting)
                VStack(alignment: .leading, spacing: 4) {
                    Text(strings.compactInstructions).font(.rounded(11, .semibold))
                        .fixedSize(horizontal: false, vertical: true)
                    if isPreview {
                        Text(compactInstructions).font(.rounded(10)).foregroundColor(.primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(6)
                            .background(RoundedRectangle(cornerRadius: 5).fill(Color.segmentBg))
                            .fixedSize(horizontal: false, vertical: true)
                    } else {
                        TextField(strings.compactInstructions, text: $compactInstructions, axis: .vertical)
                            .font(.rounded(10))
                            .lineLimit(2...4)
                            .textFieldStyle(.roundedBorder)
                            .accessibilityLabel(strings.compactInstructions)
                    }
                    Text(strings.compactInstructionsNote).font(.rounded(10)).foregroundColor(.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            settingsGroup(strings.settingsNotifications) {
                HStack(spacing: 8) {
                    footerSwitch(strings.alertCache, isOn: Binding(get: { alertsOnCache }, set: { setAlert($0, cache: true) }))
                    if alertsOnCache && !isPreview {
                        Menu {
                            ForEach(Alerts.leads, id: \.self) { lead in
                                Button(String(format: strings.alertLead, Int(lead / 60))) { alertLeadMinutes = Int(lead / 60) }
                            }
                        } label: {
                            Text(String(format: strings.alertLead, alertLeadMinutes)).font(.rounded(10, .semibold))
                                .foregroundColor(.secondaryText)
                        }
                        .menuStyle(.borderlessButton)
                        .menuIndicator(.hidden)
                        .fixedSize()
                        .accessibilityLabel(strings.alertCache)
                        .accessibilityValue(String(format: strings.alertLead, alertLeadMinutes))
                    }
                }
                footerSwitch(strings.alertQuota, isOn: Binding(get: { alertsOnQuota }, set: { setAlert($0, cache: false) }))
                if notificationsDenied {
                    Text(strings.notifyDenied).font(.rounded(10)).foregroundColor(.tone(.crit))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(12)
    }

    private func settingsGroup<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        Card {
            VStack(alignment: .leading, spacing: 10) {
                Text(title.uppercased()).font(.rounded(9, .bold)).foregroundColor(.secondaryText)
                    .accessibilityAddTraits(.isHeader)
                content()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    /// A choice with its name on the leading side and the control that makes it on the other.
    private func settingsRow<Control: View>(_ title: String, @ViewBuilder control: () -> Control) -> some View {
        HStack(spacing: 8) {
            Text(title).font(.rounded(11, .semibold)).lineLimit(1).minimumScaleFactor(0.8)
            Spacer(minLength: 8)
            control()
        }
    }

    /// One of the settings' switches, painted in the off-screen render, which cannot draw a real one.
    private func footerSwitch(_ title: String, isOn: Binding<Bool>) -> some View {
        SwitchRow(title: title, isOn: isOn, isPreview: isPreview)
    }

    /// Turning an alert on is when macOS is asked to let the app notify; a refusal turns it back off.
    private func setAlert(_ isOn: Bool, cache: Bool) {
        func store(_ value: Bool) {
            if cache { alertsOnCache = value } else { alertsOnQuota = value }
        }
        guard isOn else { return store(false) }
        Notifier.shared.authorize { granted in
            store(granted)
            notificationsDenied = !granted
        }
    }

    /// The chosen language by its own name, or "System" while the system decides.
    private var languageLabel: some View {
        HStack(spacing: 4) {
            Glyph(symbol: "globe", size: 12, weight: .regular)
            Text(languageName).font(.rounded(11, .semibold)).lineLimit(1)
            Glyph(symbol: "chevron.up.chevron.down", size: 8)
        }
        .foregroundColor(.secondaryText)
    }

    private var languageName: String {
        languageChoice == Language.system && previewLanguage == nil ? strings.followSystem : language.nativeName
    }

    private func languageButton(_ choice: String, title: String) -> some View {
        Button {
            languageChoice = choice
        } label: {
            if languageChoice == choice {
                Label(title, systemImage: "checkmark")
            } else {
                Text(title)
            }
        }
    }

    private func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            loginError = nil
        } catch {
            loginError = String(format: strings.loginError, error.localizedDescription)
        }
        launchesAtLogin = SMAppService.mainApp.status == .enabled
    }
}
