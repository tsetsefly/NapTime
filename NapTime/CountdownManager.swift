import Foundation
import Combine

class CountdownManager: ObservableObject {
    static let shared = CountdownManager()

    @Published var countdownValue: Int? = nil
    @Published var isCountingDown = false

    private init() {}

    func startCountdown(from seconds: Int) {
        countdownValue = seconds
        isCountingDown = true
    }

    func stopCountdown() {
        countdownValue = nil
        isCountingDown = false
    }
}