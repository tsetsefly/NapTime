import Foundation
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
            // AlarmSoundManager.shared.startLoopingAlarm() // ✅ This line starts the alarm sound with notifications in foreground
            print("🔔 Alarm triggered in foreground — suppressing banner/sound")
            AlarmSoundManager.shared.startLoopingAlarm()
            
            // ✅ Do NOT show banner or system sound in foreground
            completionHandler([]) // suppress all UI
        } else {
            // Default behavior for other notifications
            completionHandler([.banner, .sound])
        }
    }

    // When user taps the notification
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        if response.notification.request.identifier == "alarmNotification" {
            print("🔔 Alarm tapped in background")

            // ✅ Mark that the system already played the sound
            AlarmSoundManager.shared.markAlreadyPlayedViaNotification()
            
            DispatchQueue.main.async {
                CountdownManager.shared.stopCountdown()
            }
            // AlarmSoundManager.shared.startLoopingAlarm()
        }

        completionHandler()
    }
}