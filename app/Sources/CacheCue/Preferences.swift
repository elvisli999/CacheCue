import AppKit
import CacheCueCore

/// What the person chose in the popover's footer, kept in the app's defaults.
enum Preferences {
    static let themeKey = "appTheme"
    static let languageKey = "appLanguage"
    /// The session the person chose to keep in view.
    static let pinnedSessionKey = "pinnedSession"
    /// A session about to lose its cache comes before the latest one; on unless turned off.
    static let followUrgentKey = "followUrgent"
    /// The two kinds of notification, both off until the person turns them on.
    static let alertCacheKey = "alertCache"
    static let alertQuotaKey = "alertQuota"
    /// Minutes before a one-hour cache runs out that the warning comes.
    static let alertLeadKey = "alertLeadMinutes"
    /// What has been announced already (`AlertLedger`, as JSON).
    static let alertLedgerKey = "alertLedger"
    /// A dot in the menu bar's crescent while a session waits on the person; on unless turned off.
    static let waitingMarkKey = "waitingMark"
    /// The ids of the sessions the person lets the app compact before their cache goes cold.
    static let autoCompactKey = "autoCompactSessions"
    /// The ids of the sessions the person lets the app keep warm before their cache goes cold.
    static let keepWarmKey = "keepWarmSessions"
    /// By session: the cache expiry a compaction or a keep-warm read was last asked for.
    static let autoCompactLedgerKey = "autoCompactLedger"
    /// What a compaction the app asks for tells the summary to keep; empty leaves Claude Code's own prompt.
    static let compactInstructionsKey = "compactInstructions"
    static let defaultCompactInstructions = "Keep file paths, decisions and the reasons for them, and unfinished work."

    static var showsWaitingMark: Bool {
        UserDefaults.standard.object(forKey: waitingMarkKey) as? Bool ?? true
    }

    static var autoCompactSessions: Set<String> {
        Set(UserDefaults.standard.stringArray(forKey: autoCompactKey) ?? [])
    }

    static var keepWarmSessions: Set<String> {
        Set(UserDefaults.standard.stringArray(forKey: keepWarmKey) ?? [])
    }

    static var compactInstructions: String? {
        let text = (UserDefaults.standard.string(forKey: compactInstructionsKey) ?? defaultCompactInstructions)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return text.isEmpty ? nil : text
    }

    static var followsUrgent: Bool {
        UserDefaults.standard.object(forKey: followUrgentKey) as? Bool ?? true
    }

    static var alertLead: TimeInterval {
        let minutes = UserDefaults.standard.integer(forKey: alertLeadKey)
        let lead = TimeInterval(minutes * 60)
        return Alerts.leads.contains(lead) ? lead : Alerts.defaultLead
    }

    /// The release this build is, or `dev` for a build that is not one.
    static var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "dev"
    }

    static var versionLabel: String {
        AppVersion(version) == nil ? version : "v" + version
    }
}

/// Light, dark, or whatever the system is.
enum AppTheme: String, CaseIterable {
    case system, light, dark

    /// The footer's button steps through them in this order.
    var next: AppTheme {
        switch self {
        case .system: return .light
        case .light: return .dark
        case .dark: return .system
        }
    }

    var symbol: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        }
    }

    func label(_ strings: Strings) -> String {
        switch self {
        case .system: return strings.themeSystem
        case .light: return strings.themeLight
        case .dark: return strings.themeDark
        }
    }

    /// Nil hands the choice back to the system.
    var appearance: NSAppearance? {
        switch self {
        case .system: return nil
        case .light: return NSAppearance(named: .aqua)
        case .dark: return NSAppearance(named: .darkAqua)
        }
    }

    @MainActor
    func apply() {
        NSApplication.shared.appearance = appearance
    }

    static func stored(_ raw: String?) -> AppTheme {
        raw.flatMap(AppTheme.init(rawValue:)) ?? .system
    }
}
