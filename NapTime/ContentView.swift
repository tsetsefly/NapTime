//
//  ContentView.swift
//  NapTime
//
//  Created by Daniel on 5/27/25.
//

import SwiftUI
import UserNotifications

struct ContentView: View {
    @ObservedObject var countdownManager = CountdownManager.shared

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

            if let countdown = countdownManager.countdownValue {
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
            tickCountdown()
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
                    countdownManager.startCountdown(from: seconds)
                }
            }
        }
    }

    func stopCountdown() {
        countdownManager.stopCountdown()
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["alarmNotification"])
        AlarmSoundManager.shared.stopAlarm()
    }

    func tickCountdown() {
        guard countdownManager.isCountingDown,
              let value = countdownManager.countdownValue,
              value > 0 else { return }

        countdownManager.countdownValue = value - 1

        if countdownManager.countdownValue == 0 {
            countdownManager.isCountingDown = false
        }
    }
}