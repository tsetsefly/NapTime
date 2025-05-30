//
//  ContentView.swift
//  NapTime
//
//  Created by Daniel on 5/27/25.
//

import SwiftUI
import UserNotifications

let alarmOptions: [(label: String, seconds: Int)] = [
    ("10 minutes", 600),
    ("13 minutes", 780),
    ("15 minutes", 900),
    ("20 minutes", 1200),
    ("23 minutes", 1380),
    ("25 minutes", 1500),
    ("45 minutes", 2700),
    ("60 minutes", 3600)
]

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

            // 5-sec button to assist during debugging
            // Divider()

            // Button(action: {
            //     scheduleAlarm(in: 5)
            // }) {
            //     Text("TESTING: Set Alarm for 5 seconds")
            //         .font(.headline)
            //         .padding()
            //         .frame(maxWidth: .infinity)
            //         .background(Color.blue)
            //         .foregroundColor(.white)
            //         .cornerRadius(10)
            // }

            Divider()

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(alarmOptions, id: \.seconds) { option in
                    Button(action: {
                        scheduleAlarm(in: option.seconds)
                    }) {
                        Text(option.label)
                            .font(.headline)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
            }

            Divider()

            if countdownManager.isCountingDown, let countdown = countdownManager.countdownValue {
                Text("Alarm in: \(countdown)s")
                    .font(.title2)
                    .monospacedDigit()
                    .foregroundColor(.red)
            } else if countdownManager.alarmTriggered {
                Text("🚨 Wake up!!! 🚨")
                    .font(.title)
                    .foregroundColor(.orange)
                    .bold()
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
            if countdownManager.countdownValue == 0 || countdownManager.countdownValue == nil {
                countdownManager.stopCountdown()
            }
        }
    }

    func scheduleAlarm(in seconds: Int) {
        // ✅ Stop any currently playing alarm
        AlarmSoundManager.shared.stopAlarm()

        // ✅ Reset all alarm logic state
        AlarmSoundManager.shared.resetPlaybackState()
        CountdownManager.shared.stopCountdown()  // 🔥 This clears countdown + "Wake up!!!"

        print("Alarm reset")

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
            countdownManager.alarmTriggered = true // ✅ set alarm active
        }
    }
}