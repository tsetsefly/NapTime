//
//  ContentView.swift
//  NapTime
//
//  Created by Daniel on 5/27/25.
//

import SwiftUI
import UserNotifications

struct ContentView: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("Simple Alarm")
                .font(.largeTitle)
                .padding()

            Button("Request Notification Permission") {
                UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
                    if granted {
                        print("Permission granted.")
                    } else {
                        print("Permission denied.")
                    }
                }
            }

            Button("Set Alarm for 5 seconds from now") {
                let content = UNMutableNotificationContent()
                content.title = "⏰ Alarm"
                content.body = "Time to wake up!"
                // content.sound = UNNotificationSound.default
                content.sound = UNNotificationSound(named: UNNotificationSoundName("alarm.wav"))

                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)

                let request = UNNotificationRequest(
                    identifier: "alarmNotification",
                    content: content,
                    trigger: trigger
                )

                UNUserNotificationCenter.current().add(request) { error in
                    if let error = error {
                        print("Error scheduling notification: \(error)")
                    } else {
                        print("Alarm set for 5 seconds from now.")
                    }
                }
            }

            Button("Stop Alarm") {
                AlarmSoundManager.shared.stopAlarm()
            }
        }
        .padding()
    }
}
