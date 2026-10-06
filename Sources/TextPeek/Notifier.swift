import AppKit
import UserNotifications

@MainActor
final class Notifier: NSObject, UNUserNotificationCenterDelegate {
    private let center = UNUserNotificationCenter.current()

    override init() {
        super.init()
        center.delegate = self
    }

    func requestAuthorization() async {
        _ = try? await center.requestAuthorization(options: [.alert, .sound])
    }

    func post(title: String, subtitle: String?, body: String, sender: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.subtitle = subtitle ?? ""
        content.body = body
        content.sound = .default
        content.threadIdentifier = sender
        content.userInfo = ["url": subtitle == nil ? "sms:\(sender)" : "sms:"]
        center.add(UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil))
    }

    func askForFullDiskAccess() {
        let content = UNMutableNotificationContent()
        content.title = "TextPeek needs Full Disk Access"
        content.body = "Turn it on for TextPeek so it can see new messages."
        content.userInfo = ["url": "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles"]
        center.add(UNNotificationRequest(identifier: "full-disk-access", content: content, trigger: nil))
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        guard let url = (response.notification.request.content.userInfo["url"] as? String).flatMap(URL.init) else { return }
        await MainActor.run { _ = NSWorkspace.shared.open(url) }
    }
}
