//
//  ContentView.swift
//  NapTime
//
//  Created by Daniel on 5/27/25.
//

import SwiftUI
import UserNotifications

struct ContentView: View {
    @State private var countdownValue: Int? = nil
    @State private var isCountingDown = false

    // SwiftUI-native timer that ticks every second
    let countdownTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 20) {
            Text("Simple Alarm")
                .font(.largeTitle)

            Button("Request Notification Permission") {
                UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
                    print(granted ? "Permission granted" : "Permission denied")
                }
            }

            Button("Set Alarm for 5 seconds from now") {
                scheduleAlarm(in: 5)
            }

            if let countdown = countdownValue {
                Text("Alarm in: \(countdown)s")
                    .font(.title2)
                    .monospacedDigit()
                    .foregroundColor(.red)
            }

            Button("Stop Countdown") {
                stopCountdown()
            }
        }
        .padding()
        .onReceive(countdownTimer) { _ in
            guard isCountingDown, let value = countdownValue, value > 0 else { return }
            countdownValue = value - 1
            if countdownValue == 0 {
                isCountingDown = false
            }
        }
    }

    func scheduleAlarm(in seconds: Int) {
        let content = UNMutableNotificationContent()
        content.title = "⏰ Alarm"
        content.body = "Time to wake up!"
        content.sound = UNNotificationSound(named: UNNotificationSoundName("alarm.wav"))

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(seconds), repeats: false)
        let request = UNNotificationRequest(identifier: "alarmNotification", content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule notification: \(error)")
            } else {
                print("Alarm scheduled.")
                DispatchQueue.main.async {
                    countdownValue = seconds
                    isCountingDown = true
                }
            }
        }
    }

    func stopCountdown() {
        countdownValue = nil
        isCountingDown = false

        // ❌ Cancel all pending alarm notifications
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["alarmNotification"])

        // 🔇 Stop alarm sound if it's currently playing
        AlarmSoundManager.shared.stopAlarm()
    }
}
