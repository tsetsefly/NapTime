import Foundation
import Combine

class CountdownManager: ObservableObject {
    static let shared = CountdownManager()

    @Published var countdownValue: Int? = nil
    @Published var isCountingDown = false
    @Published var alarmTriggered: Bool = false

    private init() {}

    func startCountdown(from seconds: Int) {
        countdownValue = seconds
        isCountingDown = true
    }

    func tick() {
        guard isCountingDown, let value = countdownValue, value > 0 else { return }
        countdownValue = value - 1
        if countdownValue == 0 {
            isCountingDown = false
            alarmTriggered = true // ✅ mark alarm as fired
        }
    }

    func stopCountdown() {
        print("⏹ Stopping countdown")
        countdownValue = nil
        isCountingDown = false
        alarmTriggered = false // ✅ reset state
    }
}