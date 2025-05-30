import Foundation
import Combine

class CountdownManager: ObservableObject {
    static let shared = CountdownManager()

    @Published var countdownValue: Int? = nil
    @Published var isCountingDown = false
    @Published var alarmTriggered = false

    private var alarmEndDate: Date?

    func startCountdown(from seconds: Int) {
        alarmEndDate = Date().addingTimeInterval(TimeInterval(seconds))
        isCountingDown = true
        alarmTriggered = false
        updateCountdown()
    }

    func stopCountdown() {
        isCountingDown = false
        countdownValue = nil
        alarmEndDate = nil
        alarmTriggered = false
    }

    func updateCountdown() {
        guard isCountingDown, let end = alarmEndDate else { return }

        let remaining = Int(end.timeIntervalSinceNow)
        if remaining > 0 {
            countdownValue = remaining
        } else {
            countdownValue = 0
            isCountingDown = false
            alarmTriggered = true
        }
    }
}