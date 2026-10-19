import AppKit
import UserNotifications
import CacheCueCore

/// System notifications, for what the menu bar cannot say to someone who is not looking at
/// it: a cache about to go cold, a limit filling up. Off until the person turns an alert on,
/// which is also the first time macOS is asked for permission.
@MainActor
final class Notifier: NSObject, UNUserNotificationCenterDelegate {
    static let shared = Notifier()
    private nonisolated static let sessionKey = "session"

    /// Brings a session into view when its notification is pressed.
    var showSession: ((String) -> Void)?
    /// Carries out a button pressed on a notification: keep that session's cache warm, or compact it.
    var act: ((String, BeforeExpiry) -> Void)?

    /// Notifications belong to an app bundle; the bare executable (a test, `--render`) has none.
    private var center: UNUserNotificationCenter? {
        Bundle.main.bundleURL.pathExtension == "app" ? .current() : nil
    }

    func start(strings: Strings) {
        center?.delegate = self
        setButtons(strings)
    }

    /// The buttons a notification about a cache may carry, named in the person's language.
    private func setButtons(_ strings: Strings) {
        let warm = UNNotificationAction(identifier: BeforeExpiry.warm.rawValue, title: strings.choiceWarm)
        let compact = UNNotificationAction(identifier: BeforeExpiry.compact.rawValue, title: strings.choiceCompact)
        center?.setNotificationCategories([
            UNNotificationCategory(identifier: Notifier.category([.warm, .compact]), actions: [warm, compact], intentIdentifiers: []),
            UNNotificationCategory(identifier: Notifier.category([.warm]), actions: [warm], intentIdentifiers: []),
            UNNotificationCategory(identifier: Notifier.category([.compact]), actions: [compact], intentIdentifiers: []),
        ])
    }

    private static func category(_ actions: [BeforeExpiry]) -> String {
        "cache." + actions.map(\.rawValue).joined(separator: ".")
    }

    /// Asks macOS for permission, the first time; answers false when it is refused, now or before.
    func authorize(_ done: @escaping (Bool) -> Void) {
        guard let center else { return done(false) }
        center.requestAuthorization(options: [.alert, .sound]) { granted, _ in
            Task { @MainActor in done(granted) }
        }
    }

    /// `actions`: the buttons to offer, those the session's plugin carries out.
    func post(_ alert: Alert, strings: Strings, actions: [BeforeExpiry] = []) {
        guard let center else { return }
        let content = UNMutableNotificationContent()
        if !actions.isEmpty {
            // The language may have changed since the buttons were named.
            setButtons(strings)
            content.categoryIdentifier = Notifier.category(actions)
        }
        content.title = alert.title(strings)
        content.body = alert.body(strings)
        content.sound = .default
        if let sessionID = alert.sessionID {
            content.userInfo = [Notifier.sessionKey: sessionID]
        }
        center.add(UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil))
    }

    // The app has no window to be in front, so a notification shows whenever it arrives.
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter, willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let sessionID = response.notification.request.content.userInfo[Notifier.sessionKey] as? String
        let action = BeforeExpiry(rawValue: response.actionIdentifier)
        Task { @MainActor in
            if let sessionID {
                if let action, action != .leave { self.act?(sessionID, action) } else { self.showSession?(sessionID) }
            }
            completionHandler()
        }
    }
}
