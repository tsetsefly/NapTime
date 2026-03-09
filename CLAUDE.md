# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

NapTime is an iOS nap alarm app built with SwiftUI. Users select a preset duration, a local notification is scheduled, and an alarm sound plays when time is up. The app handles both foreground and background alarm delivery.

## Build & Run

This is an Xcode project (NapTime.xcodeproj) — no Swift Package Manager or CocoaPods.

```bash
# Build from command line
xcodebuild -project NapTime.xcodeproj -scheme NapTime -sdk iphonesimulator build

# Run tests
xcodebuild -project NapTime.xcodeproj -scheme NapTime -sdk iphonesimulator test
```

Most development is done by opening `NapTime.xcodeproj` in Xcode directly.

## Architecture

The app uses a singleton-based architecture with four main components:

- **ContentView.swift** — Main UI. Contains the alarm duration grid, countdown display, and alert flows for silent mode/DND warnings. Schedules `UNNotificationRequest` and drives the countdown timer via `Timer.publish`.
- **CountdownManager.swift** — `ObservableObject` singleton (`CountdownManager.shared`) that tracks countdown state using a target `Date` rather than decrementing a counter. The UI reads `countdownValue`, `isCountingDown`, and `alarmTriggered`.
- **AlarmSoundManager.swift** — Singleton that manages `AVAudioPlayer` for looping alarm playback. Has a `alreadyPlayedViaNotification` flag to prevent double-playing when the notification system already played the sound.
- **NotificationDelegate.swift** — `UNUserNotificationCenterDelegate` singleton. In foreground: suppresses the system banner and plays alarm via `AlarmSoundManager`. On background tap: marks sound as already played and stops the countdown.

## Key Patterns

- All managers are singletons accessed via `.shared` — state flows through `CountdownManager` as the single `@ObservedObject` in `ContentView`.
- Alarm durations are defined in the top-level `alarmOptions` array in ContentView.swift.
- The alarm sound file is `NapTime/alarm.wav`, referenced by name in both the notification content and `AVAudioPlayer`.
- The app uses two-step alert flows: one before setting an alarm (silent mode warning) and one after stopping (re-enable silent mode reminder).
