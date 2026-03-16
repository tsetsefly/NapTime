import AppIntents
import AlarmKit

struct RestartAlarmIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Restart Alarm"
    static var description: IntentDescription = "Restarts the current NapTime alarm with the same duration."

    private static let durationKey = "lastAlarmDurationSeconds"
    private static let labelKey = "lastAlarmDurationLabel"

    static func saveLastAlarm(seconds: Int, label: String) {
        let defaults = UserDefaults(suiteName: "group.tsetsefly.NapTime")
        defaults?.set(seconds, forKey: durationKey)
        defaults?.set(label, forKey: labelKey)
    }

    func perform() async throws -> some IntentResult {
        let manager = AlarmManager.shared
        let defaults = UserDefaults(suiteName: "group.tsetsefly.NapTime")

        guard let seconds = defaults?.integer(forKey: Self.durationKey), seconds > 0,
              let label = defaults?.string(forKey: Self.labelKey) else {
            return .result()
        }

        // Cancel existing alarm
        if let alarms = try? manager.alarms {
            for alarm in alarms {
                try? manager.cancel(id: alarm.id)
            }
        }

        // Reschedule with the same duration
        let alert = AlarmPresentation.Alert(title: "Time to wake up!")
        let countdown = AlarmPresentation.Countdown(title: "Napping...")
        let presentation = AlarmPresentation(alert: alert, countdown: countdown)

        let metadata = NapTimeMetadata(durationLabel: label, durationSeconds: seconds)
        let attributes = AlarmAttributes<NapTimeMetadata>(
            presentation: presentation,
            metadata: metadata,
            tintColor: .blue
        )

        _ = try await manager.schedule(
            id: UUID(),
            configuration: .timer(
                duration: TimeInterval(seconds),
                attributes: attributes,
                stopIntent: StopAlarmIntent()
            )
        )

        return .result()
    }
}
