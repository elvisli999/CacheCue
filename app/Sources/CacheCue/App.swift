import AppKit
import ServiceManagement
import SwiftUI
import CacheCueCore

/// Reads the snapshot folder and keeps the countdowns moving.
@MainActor
final class UsageModel: ObservableObject {
    @Published private(set) var summary: Summary
    /// The last seven days of what the cache cost, for the ledger card.
    @Published private(set) var week = Week()
    private let directory = SnapshotStore.defaultDirectory
    private let defaults = UserDefaults.standard
    private var snapshots: [Snapshot] = []
    private var states: [String: SessionState] = [:]
    private var ticks = 0

    /// Limit readings and daily totals, kept on this Mac; written at most once a minute.
    private let historyURL = HistoryStore.defaultURL
    private var history: History
    private var savedHistory: History
    private var lastSave = Date.distantPast

    /// The session kept in view by choice; nil follows whichever did something last.
    private var pinned: String? {
        get { defaults.string(forKey: Preferences.pinnedSessionKey) }
        set { defaults.set(newValue, forKey: Preferences.pinnedSessionKey) }
    }

    func pin(_ sessionID: String?) {
        pinned = sessionID
        summary = summarize(Date())
    }

    /// The sessions the person lets the app compact, or keep warm, before their cache goes cold.
    @Published private(set) var autoCompacted = Preferences.autoCompactSessions
    @Published private(set) var keptWarm = Preferences.keepWarmSessions

    /// What the person chose for each session that has a choice other than leaving it.
    var choices: [String: BeforeExpiry] {
        var choices: [String: BeforeExpiry] = [:]
        for id in keptWarm { choices[id] = .warm }
        for id in autoCompacted { choices[id] = .compact }
        return choices
    }

    func setChoice(_ sessionID: String, _ choice: BeforeExpiry) {
        if choice == .compact { autoCompacted.insert(sessionID) } else { autoCompacted.remove(sessionID) }
        if choice == .warm { keptWarm.insert(sessionID) } else { keptWarm.remove(sessionID) }
        saveChoices()
    }

    private func saveChoices() {
        defaults.set(autoCompacted.sorted(), forKey: Preferences.autoCompactKey)
        defaults.set(keptWarm.sorted(), forKey: Preferences.keepWarmKey)
    }

    private func summarize(_ now: Date) -> Summary {
        var summary = Summary(
            snapshots: snapshots, now: now, pinned: pinned, states: states, followsUrgent: Preferences.followsUrgent)
        summary.setPace(from: history, now: now)
        summary.setTurnShares(from: history)
        return summary
    }

    init() {
        AppTheme.stored(UserDefaults.standard.string(forKey: Preferences.themeKey)).apply()
        SnapshotStore.prune(in: directory, now: Date())
        // A plugin this app installed moves with the app: an update brings its copy along.
        let home = FileManager.default.homeDirectoryForCurrentUser
        PluginSetup.refresh(bundled: PluginSetup.bundled(resources: Bundle.main.resourceURL), home: home)
        // The desktop app's sessions load the copy Claude Code installed, not that folder: after
        // an update of this app, Claude Code is asked once to bring its copy along.
        DispatchQueue.global(qos: .utility).async {
            PluginSetup.updateIfBehind(home: home, claude: PluginSetup.claudeExecutable(home: home))
        }
        snapshots = SnapshotStore.load(from: directory)
        states = SnapshotStore.loadStates(from: directory)
        history = HistoryStore.load(from: historyURL)
        savedHistory = history
        summary = Summary(snapshots: [], now: Date())
        summary = summarize(Date())
        week = history.week(now: Date())
        Notifier.shared.start(strings: .of(Language.resolve(choice: defaults.string(forKey: Preferences.languageKey))))
        Notifier.shared.showSession = { [weak self] id in self?.pin(id) }
        Notifier.shared.act = { [weak self] id, action in self?.send(action, to: id, at: Date()) }
        // .common keeps the countdown moving while the popover is open.
        let timer = Timer(timeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.refresh() }
        }
        RunLoop.main.add(timer, forMode: .common)
    }

    /// Every second the countdowns move; every other second the files are read again.
    private func refresh() {
        ticks += 1
        let now = Date()
        let isReading = ticks % 2 == 0
        if isReading {
            snapshots = SnapshotStore.load(from: directory)
            states = SnapshotStore.loadStates(from: directory)
            history.record(snapshots: snapshots, states: states, fiveHour: summary.fiveHour, now: now)
        }
        summary = summarize(now)
        // A pinned session that has gone quiet lets go by itself.
        if pinned != nil && !summary.isPinned {
            pinned = nil
        }
        if isReading {
            history.sample(limits: summary.limits, now: now)
            week = history.week(now: now)
            if history != savedHistory, now.timeIntervalSince(lastSave) >= 60 {
                try? HistoryStore.save(history, to: historyURL)
                savedHistory = history
                lastSave = now
            }
        }
        announce(now)
        if isReading { actWhereAsked(now) }
    }

    /// Leaves a request for each session whose cache is about to go cold, of those the person
    /// chose keeping warm or compacting for; the plugin in the session carries it out.
    private func actWhereAsked(_ now: Date) {
        // A session no longer on record is no longer asked about.
        let known = Set(snapshots.map(\.sessionID))
        if !autoCompacted.isSubset(of: known) || !keptWarm.isSubset(of: known) {
            autoCompacted.formIntersection(known)
            keptWarm.formIntersection(known)
            saveChoices()
        }
        let answered = states.values.flatMap {
            [$0.compact?.request, $0.compactFailed?.request, $0.warm?.request, $0.warmFailed?.request]
        }
        SnapshotStore.clearRequests(
            in: directory, answered: Set(answered.compactMap { $0 }), now: now, life: AutoCompact.requestLife)
        let choices = self.choices
        guard !choices.isEmpty else { return }
        let stored = defaults.dictionary(forKey: Preferences.autoCompactLedgerKey) as? [String: Double] ?? [:]
        var ledger = stored
        let due = AutoCompact.due(sessions: summary.every, choices: choices, ledger: &ledger)
        if ledger != stored {
            defaults.set(ledger, forKey: Preferences.autoCompactLedgerKey)
        }
        for item in due {
            send(item.action, to: item.session.id, at: now)
        }
    }

    /// Asks a session's plugin to keep its cache warm or to compact it: on the person's
    /// choice for that session, or a button they pressed on a notification.
    func send(_ action: BeforeExpiry, to sessionID: String, at now: Date) {
        guard action != .leave else { return }
        try? SnapshotStore.write(
            SessionRequest(
                sessionID: sessionID, action: action == .warm ? SessionRequest.warm : SessionRequest.compact,
                id: UUID().uuidString, at: now.timeIntervalSince1970,
                instructions: action == .compact ? Preferences.compactInstructions : nil),
            in: directory)
    }

    /// Posts what is due, of the notifications the person has turned on.
    private func announce(_ now: Date) {
        let isCacheOn = defaults.bool(forKey: Preferences.alertCacheKey)
        let isQuotaOn = defaults.bool(forKey: Preferences.alertQuotaKey)
        guard isCacheOn || isQuotaOn else { return }
        let stored = defaults.data(forKey: Preferences.alertLedgerKey)
            .flatMap { try? JSONDecoder().decode(AlertLedger.self, from: $0) } ?? AlertLedger()
        var ledger = stored
        let due = Alerts.due(
            sessions: summary.every, limits: summary.limits, now: now, lead: Preferences.alertLead,
            cache: isCacheOn, quota: isQuotaOn, ledger: &ledger)
        if ledger != stored {
            defaults.set(try? JSONEncoder().encode(ledger), forKey: Preferences.alertLedgerKey)
        }
        guard !due.isEmpty else { return }
        let strings = Strings.of(Language.resolve(choice: defaults.string(forKey: Preferences.languageKey)))
        for alert in due {
            let session = summary.every.first { $0.id == alert.sessionID }
            Notifier.shared.post(alert, strings: strings, actions: session.map(AutoCompact.actions(for:)) ?? [])
        }
    }
}

struct UsageBarApp: App {
    @StateObject private var model = UsageModel()
    @StateObject private var updater = Updater()
    @StateObject private var support = SupportModel(watching: true)

    var body: some Scene {
        MenuBarExtra {
            PopoverView(
                summary: model.summary, week: model.week, updater: updater, pin: model.pin,
                choices: model.choices, setChoice: model.setChoice, support: support,
                isShowingSupport: support.isPresented, unreadReplies: support.unread.count)
                .background(Material.regular)
        } label: {
            Image(nsImage: MenuBarLabel.image(for: model.summary, marksWaiting: Preferences.showsWaitingMark))
                .accessibilityLabel(MenuBarLabel.spoken(
                    for: model.summary,
                    strings: .of(Language.resolve(choice: UserDefaults.standard.string(forKey: Preferences.languageKey)))))
        }
        .menuBarExtraStyle(.window)
    }
}

@main
enum Entry {
    @MainActor
    static func main() {
        let arguments = CommandLine.arguments

        // `statusline` is what Claude Code's statusLine setting runs: session JSON on stdin,
        // the session's snapshot left for the menu bar, and nothing printed, so the terminal
        // shows no line. No AppKit, no window: it runs every few seconds.
        if arguments.dropFirst().first == "statusline" {
            let directory = SnapshotStore.defaultDirectory
            let input = FileHandle.standardInput.readDataToEndOfFile()
            let sessionID = (try? JSONSerialization.jsonObject(with: input) as? [String: Any])?["session_id"] as? String
            let previous = sessionID.flatMap { SnapshotStore.read($0, in: directory) }
            if let snapshot = StatusLine.snapshot(input: input, now: Date(), previous: previous), snapshot != previous {
                try? SnapshotStore.write(snapshot, in: directory)
            }
            // `--then <command>`: a status line that was there before this app is handed the
            // same input, and what it prints is the terminal's status line.
            if arguments.count >= 4, arguments[2] == "--then" {
                exit(StatusLineChain.run(arguments[3], input: input))
            }
            return
        }
        // `setup-statusline [--keep | --force | --remove]` does what the popover's Connect button
        // for terminal sessions does; `--remove` takes this app's command out again.
        if arguments.dropFirst().first == "setup-statusline" {
            let path = StatusLineSetup.defaultSettingsURL.path
            do {
                if arguments.contains("--remove") {
                    try StatusLineSetup.remove()
                    print("CacheCue's command is out of \(path).")
                    return
                }
                var kept: String?
                if case .other(let command) = StatusLineSetup.state() {
                    if arguments.contains("--keep") {
                        kept = command
                    } else if !arguments.contains("--force") {
                        print("Another status line is configured:\n  \(command)\nRun again with --keep to keep it running behind CacheCue, or with --force to replace it.")
                        exit(1)
                    }
                }
                try StatusLineSetup.install(executable: Bundle.main.executablePath ?? arguments[0], keeping: kept)
                print(kept == nil
                    ? "Terminal sessions connected through \(path). Nothing is shown in the terminal; the figures are in the menu bar."
                    : "Terminal sessions connected through \(path). Your status line still runs and shows as before.")
            } catch {
                print("Setup failed: \(error.localizedDescription)")
                exit(1)
            }
            return
        }

        let directory = SnapshotStore.defaultDirectory
        let history = HistoryStore.load(from: HistoryStore.defaultURL)
        var summary = Summary(
            snapshots: SnapshotStore.load(from: directory), now: Date(),
            states: SnapshotStore.loadStates(from: directory), followsUrgent: Preferences.followsUrgent)
        summary.setPace(from: history, now: Date())
        summary.setTurnShares(from: history)

        // `status --json` prints the figures for a script: a shortcut, a launcher, a dashboard.
        if arguments.dropFirst().first == "status" {
            FileHandle.standardOutput.write(summary.json(now: Date()))
            FileHandle.standardOutput.write(Data("\n".utf8))
            return
        }

        func value(after flag: String) -> String? {
            arguments.firstIndex(of: flag).flatMap { arguments.indices.contains($0 + 1) ? arguments[$0 + 1] : nil }
        }
        // `--lang <code>` picks the language for the two commands below; otherwise the
        // person's own choice stands.
        let language = Language.resolve(
            choice: value(after: "--lang") ?? UserDefaults.standard.string(forKey: Preferences.languageKey))

        // `--dump` prints the figures as text and exits: a check that needs no screen.
        if arguments.contains("--dump") {
            print(summary.titleText)
            for row in summary.rows(.of(language)) {
                print(row ?? "────")
            }
            return
        }
        // `--render-icon <file.png>` draws the app icon at 1024 points, for the build script.
        if let file = value(after: "--render-icon") {
            Render.writeIcon(to: URL(fileURLWithPath: file))
            return
        }
        // `--login-status` says whether macOS has this app down as a login item.
        if arguments.contains("--login-status") {
            switch SMAppService.mainApp.status {
            case .enabled: print("enabled")
            case .notRegistered: print("notRegistered")
            case .requiresApproval: print("requiresApproval")
            case .notFound: print("notFound")
            @unknown default: print("unknown")
            }
            return
        }
        // `--render <folder> [--dark] [--lang <code>] [--page guide|<lesson id>]` writes the
        // popover and the menu bar label as PNGs.
        if let folder = value(after: "--render") {
            // `support`, `tickets` and `ticket` draw the support pages with sample tickets, not real
            // ones; `reply` draws the first page as it looks when support has answered.
            let name = value(after: "--page")
            let isSupportPage = ["support", "tickets", "ticket", "reply"].contains(name ?? "")
            // The About page has the way into support, so it is drawn with a support model too.
            let support = isSupportPage ? SupportModel.sample(name ?? "") : name == "about" ? SupportModel() : nil
            // `setup` draws the first page of a Mac where nothing feeds the app yet.
            // `kept` draws a terminal connected with an earlier status line still running behind.
            let isSetupPage = name == "setup" || name == "kept"
            let page: Page = isSupportPage || isSetupPage ? .dashboard
                : name.map { $0 == "guide" ? .guide : $0 == "about" ? .about : $0 == "settings" ? .settings : .lesson($0) } ?? .dashboard
            Render.write(
                summary, to: URL(fileURLWithPath: folder), dark: arguments.contains("--dark"), language: language,
                page: page, support: support, name: name, week: history.week(now: Date()),
                // `--auto-compact` and `--keep-warm` draw the session in view with that chosen for it.
                choices: summary.current.map { current in
                    arguments.contains("--keep-warm") ? [current.id: .warm]
                        : arguments.contains("--auto-compact") ? [current.id: .compact] : [:]
                } ?? [:],
                // `--unread` draws a reply from support waiting; `--contrast` the system's "Increase
                // contrast"; `--no-color` its "Differentiate without colour".
                unread: arguments.contains("--unread") || name == "reply" ? 1 : 0,
                contrast: arguments.contains("--contrast"), marksLevels: arguments.contains("--no-color"))
            return
        }
        // Anything else on the command line is a mistake, not a reason to open the app.
        if arguments.count > 1 {
            print("usage: CacheCue [statusline [--then <command>] | setup-statusline [--keep | --force | --remove] | status --json | --dump | --render <folder> | --render-icon <file.png> | --login-status]")
            exit(64)
        }
        // One menu bar item is enough: a second launch leaves the first in place.
        if let bundleID = Bundle.main.bundleIdentifier,
           NSRunningApplication.runningApplications(withBundleIdentifier: bundleID).count > 1 {
            return
        }
        UsageBarApp.main()
    }
}

/// Off-screen pictures of the two things the app draws, for looking at a design change
/// without opening the menu.
@MainActor
enum Render {
    static func write(
        _ summary: Summary, to folder: URL, dark: Bool, language: Language, page: Page, support: SupportModel? = nil,
        name: String? = nil, week: Week = Week(), choices: [String: BeforeExpiry] = [:], unread: Int = 0,
        contrast: Bool = false, marksLevels: Bool = false
    ) {
        Palette.forcesStrong = contrast
        let appearance = NSAppearance(
            named: contrast
                ? (dark ? .accessibilityHighContrastDarkAqua : .accessibilityHighContrastAqua)
                : (dark ? .darkAqua : .aqua))!
        NSApplication.shared.appearance = appearance
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        var suffix = "\(language.rawValue)-\(dark ? "dark" : "light")"
        switch page {
        case .dashboard: break
        case .guide: suffix = "guide-" + suffix
        case .lesson(let id): suffix = "lesson-\(id)-" + suffix
        case .about: suffix = "about-" + suffix
        case .settings: suffix = "settings-" + suffix
        }
        if page == .dashboard, support != nil || name == "setup" || name == "kept", let name { suffix = "\(name)-" + suffix }
        if unread > 0, name != "reply" { suffix = "unread-" + suffix }
        if contrast { suffix += "-contrast" }
        if marksLevels { suffix += "-nocolor" }

        appearance.performAsCurrentDrawingAppearance {
            let backdrop = dark ? Color(white: 0.16) : Color(white: 0.93)
            let popover = PopoverView(
                summary: summary, week: week, isPreview: true, previewLanguage: language, initialPage: page,
                choices: choices, support: support,
                isShowingSupport: support?.isPresented ?? false, unreadReplies: unread,
                previewsSetup: name == "setup", previewsKept: name == "kept")
                .environment(\.forcesLevelMarks, marksLevels)
                .background(backdrop)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(16)
                .background(dark ? Color(white: 0.08) : Color(white: 0.80))
                .environment(\.colorScheme, dark ? .dark : .light)
            let renderer = ImageRenderer(content: popover)
            renderer.scale = 2
            // Twice the points, so the picture stays sharp on a high-density screen.
            save(renderer.nsImage, to: folder.appendingPathComponent("popover-\(suffix).png"), scale: 2)

            // The label on a strip the shade of a menu bar.
            let label = MenuBarLabel.image(for: summary, marksWaiting: true)
            let strip = NSImage(size: NSSize(width: label.size.width + 24, height: 24), flipped: false) { rect in
                (dark ? NSColor(white: 0.14, alpha: 1) : NSColor(white: 0.90, alpha: 1)).setFill()
                rect.fill()
                label.draw(in: NSRect(x: 12, y: 1, width: label.size.width, height: label.size.height))
                return true
            }
            save(strip, to: folder.appendingPathComponent("label-\(suffix).png"), scale: 4)
        }
    }

    /// The app icon: a terracotta crescent inside a faint corona, on a dark rounded tile.
    static func writeIcon(to url: URL) {
        let side: CGFloat = 1024
        let unit = side / 512
        let moon = Palette.terracottaLight
        let icon = NSImage(size: NSSize(width: side, height: side), flipped: true) { rect in
            let tile = NSBezierPath(
                roundedRect: rect.insetBy(dx: 32 * unit, dy: 32 * unit), xRadius: 104 * unit, yRadius: 104 * unit)
            NSColor(white: 0.08, alpha: 1).setFill()
            tile.fill()

            // The bite is cleared inside a layer of its own, so it cuts the moon and not the tile.
            if let context = NSGraphicsContext.current {
                let rects = Crescent.rects(in: side)
                context.saveGraphicsState()
                context.cgContext.beginTransparencyLayer(auxiliaryInfo: nil)
                moon.setFill()
                NSBezierPath(ovalIn: rects.moon).fill()
                context.compositingOperation = .clear
                NSBezierPath(ovalIn: rects.bite).fill()
                context.cgContext.endTransparencyLayer()
                context.restoreGraphicsState()
            }

            let corona = NSBezierPath(ovalIn: rect.insetBy(dx: (256 - 175) * unit, dy: (256 - 175) * unit))
            corona.lineWidth = 14 * unit
            moon.withAlphaComponent(0.15).setStroke()
            corona.stroke()
            return true
        }
        save(icon, to: url)
    }

    private static func save(_ image: NSImage?, to url: URL, scale: CGFloat = 1) {
        guard let image else { return }
        let size = NSSize(width: image.size.width * scale, height: image.size.height * scale)
        guard let bitmap = NSBitmapImageRep(
            bitmapDataPlanes: nil, pixelsWide: Int(size.width), pixelsHigh: Int(size.height), bitsPerSample: 8,
            samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0,
            bitsPerPixel: 0)
        else { return }
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
        image.draw(in: NSRect(origin: .zero, size: size))
        NSGraphicsContext.restoreGraphicsState()
        try? bitmap.representation(using: .png, properties: [:])?.write(to: url)
        print("wrote \(url.path)")
    }
}

extension SupportModel {
    /// Sample content for the off-screen render of the support pages.
    static func sample(_ page: String) -> SupportModel {
        let model = SupportModel()
        model.isPresented = page != "reply"
        let json = """
        {"ticket":{"id":"T1","email":"you@example.com","description":"The countdown shows --:-- after my first turn in the desktop app.",
          "attachment_url":"/files/shot.png","status":"replied","created_at":"2026-10-11 20:14"},
         "replies":[{"id":1,"message":"Thanks for the report. Which version are you on? It is at the bottom of the popover.","is_admin":1,"attachment_url":null,"created_at":"2026-10-11 21:02"},
                    {"id":2,"message":"1.0.1","is_admin":0,"attachment_url":null,"created_at":"2026-10-11 21:10"}]}
        """
        let thread = try? JSONDecoder().decode(SupportThread.self, from: Data(json.utf8))
        if page == "tickets" || page == "ticket" {
            model.tab = .tickets
            model.tickets = thread.map { [$0.ticket] } ?? []
        }
        if page == "ticket" {
            model.openTicket = "T1"
            model.thread = thread
        }
        return model
    }
}
