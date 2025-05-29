import UserNotifications

class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationDelegate()  // ✅ This line creates the shared instance

    private override init() {
        super.init()
    }

    // Foreground notifications
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        if notification.request.identifier == "alarmNotification" {
            AlarmSoundManager.shared.startLoopingAlarm()
        }

        completionHandler([.banner, .sound])
    }

    // When user taps the notification
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        if response.notification.request.identifier == "alarmNotification" {
            AlarmSoundManager.shared.startLoopingAlarm()
        }

        completionHandler()
    }
}