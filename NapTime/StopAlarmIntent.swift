import AppIntents
import AlarmKit

struct StopAlarmIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Stop Alarm"
    static var description: IntentDescription = "Stops the current NapTime alarm."

    func perform() async throws -> some IntentResult {
        let manager = AlarmManager.shared
        if let alarms = try? manager.alarms {
            for alarm in alarms {
                try? manager.cancel(id: alarm.id)
            }
        }
        return .result()
    }
}
