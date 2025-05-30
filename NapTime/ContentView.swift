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
    @State private var soundSetting: UNNotificationSetting = .notSupported

    let countdownTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    func checkNotificationPermission() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                notificationPermissionGranted = (
                    settings.authorizationStatus == .authorized ||
                    settings.authorizationStatus == .provisional
                )
                soundSetting = settings.soundSetting
            }
        }
    }

    func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
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

            if soundSetting == .disabled {
                VStack(spacing: 6) {
                    Text("🔇 Notification sounds are disabled.\nAlarms may not be audible.")
                        .font(.footnote)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)

                    Button("Open Settings") {
                        openSettings()
                    }
                    .font(.footnote)
                    .padding(6)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(6)
                }
            } else if soundSetting == .enabled {
                Text("✅ Notification sounds are enabled.")
                    .font(.footnote)
                    .foregroundColor(.green)
            }

            Button(action: {
                UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, _ in
                    print(granted ? "Permission granted" : "Permission denied")
                    checkNotificationPermission()
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

            Divider()

            Button(action: {
                scheduleAlarm(in: 5)
            }) {
                Text("TESTING: Set Alarm for 5 seconds")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }

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
            countdownManager.updateCountdown()
        }
        .onAppear {
            checkNotificationPermission()
            if countdownManager.countdownValue == 0 || countdownManager.countdownValue == nil {
                countdownManager.stopCountdown()
            }
        }
    }

    func scheduleAlarm(in seconds: Int) {
        AlarmSoundManager.shared.stopAlarm()
        AlarmSoundManager.shared.resetPlaybackState()
        CountdownManager.shared.stopCountdown()

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
            countdownManager.alarmTriggered = true
        }
    }
}
