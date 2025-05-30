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
    @State private var notificationPermissionGranted: Bool? = nil

    let countdownTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    func checkNotificationPermission() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                notificationPermissionGranted = (
                    settings.authorizationStatus == .authorized ||
                    settings.authorizationStatus == .provisional
                )
            }
        }
    }

    var body: some View {
        VStack(spacing: 20) {
            Text("NapTime Alarm")
                .font(.largeTitle)

            if let permission = notificationPermissionGranted {
                Text(permission ? "🔔 Notifications Enabled" : "🚫 Notifications Disabled")
                    .font(.subheadline)
                    .foregroundColor(permission ? .green : .red)
            }

            Button(action: {
                UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, _ in
                    print(granted ? "Permission granted" : "Permission denied")
                    checkNotificationPermission() // ✅ refresh the status
                }
            }) {
                Text("Request Notification Permission")
                    .font(.subheadline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.gray.opacity(0.2))
                    .foregroundColor(.primary)
                    .cornerRadius(10)
            }

            Button(action: {
                scheduleAlarm(in: 5)
            }) {
                Text("Set Alarm for 5 seconds")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }

            if let countdown = countdownManager.countdownValue {
                Text("Alarm in: \(countdown)s")
                    .font(.title2)
                    .monospacedDigit()
                    .foregroundColor(.red)
            }

            Button(action: {
                stopCountdown()
            }) {
                Text("Stop Alarm")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .padding()
        .onReceive(countdownTimer) { _ in
            tickCountdown()
        }
        .onAppear {
            checkNotificationPermission()
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