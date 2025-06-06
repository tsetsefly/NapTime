//
//  ContentView.swift
//  NapTime
//
//  Created by Daniel on 5/27/25.
//

import SwiftUI
import UserNotifications

// Defines preset alarm durations (label, time in seconds)
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
    // Tracks iOS sound permission (enabled/disabled)
    @State private var soundSetting: UNNotificationSetting = .notSupported
    
    // Shared countdown manager instance (tracks countdown + alarm state)
    @ObservedObject var countdownManager = CountdownManager.shared
    
    // Tracks if user granted notification permissions
    @State private var notificationPermissionGranted: Bool? = nil
    
    // Show alert before setting alarm (re: silent/DND warning)
    @State private var showSilentModeWarning = false
    @State private var pendingAlarmTime: Int? = nil
    
    // Show alert after stopping alarm (re-enable silent/DND)
    @State private var showRestoreSilentModeReminder = false

    // Fires every 1 second to update UI countdown
    let countdownTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    // Queries notification permissions
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

            // Notification permission status text
            if let permission = notificationPermissionGranted {
                Text(permission ? "🔔 Notifications Enabled" : "🚫 Notifications Disabled")
                    .font(.subheadline)
                    .foregroundColor(permission ? .green : .red)
            }
            
            // Sound setting status
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

            // Request notifications permission button
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

            // // 5-sec alarm for debugging, testing
            // Divider()

            // Button(action: {
            //     pendingAlarmTime = 5
            //     showSilentModeWarning = true
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

             // Alarm buttons in a grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(alarmOptions, id: \.seconds) { option in
                    Button(action: {
                        pendingAlarmTime = option.seconds
                        showSilentModeWarning = true
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

            // Countdown display or wake-up alert
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

            // Stop alarm button
            Button(action: {
                stopCountdown()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    showRestoreSilentModeReminder = true
                }
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
        .alert("🚨 Reminder 🚨", isPresented: $showSilentModeWarning, actions: {
            Button("Continue") {
                if let seconds = pendingAlarmTime {
                    scheduleAlarm(in: seconds)
                }
            }
            Button("Cancel", role: .cancel) {
                pendingAlarmTime = nil
            }
        }, message: {
            Text("Make sure your phone is not on Silent Mode or Do Not Disturb, otherwise the alarm will NOT sound.")
        })
        .alert("🚨 Reminder 🚨", isPresented: $showRestoreSilentModeReminder, actions: {
            Button("OK") {
                stopCountdown()
            }
        }, message: {
            Text("You can now re-enable Silent Mode or Do Not Disturb if you'd like.")
        })
    }

    // Schedules a local notification and starts countdown
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

    // Stops countdown and alarm sound
    func stopCountdown() {
        countdownManager.stopCountdown()
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["alarmNotification"])
        AlarmSoundManager.shared.stopAlarm()
    }

    // Decrements countdown timer every second, when reaches 0 triggers alarm display state and stops countdown
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
