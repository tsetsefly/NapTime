//
//  NapTimeApp.swift
//  NapTime
//
//  Created by Daniel on 5/27/25.
//

import SwiftUI
import UserNotifications

@main
struct NapTimeApp: App {
    init() {
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                // .onAppear {
                //     // Automatically start the alarm sound when the app opens
                //     AlarmSoundManager.shared.startLoopingAlarm()
                // }
        }
    }
}