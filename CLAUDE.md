# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

NapTime is an iOS nap alarm app built with SwiftUI and AlarmKit (iOS 26.1+). Users select a preset duration, an alarm is scheduled via AlarmKit, and the system handles countdown display on the Lock Screen, Dynamic Island, and alarm alert delivery. AlarmKit breaks through Silent Mode and Do Not Disturb automatically.

## Build & Run

This is an Xcode project (NapTime.xcodeproj) — requires Xcode 26+ with the iOS 26.1+ SDK.

```bash
# Build from command line
xcodebuild -project NapTime.xcodeproj -scheme NapTime -sdk iphoneos build
```

Most development is done by opening `NapTime.xcodeproj` in Xcode directly. AlarmKit alarms require a **physical device** — they do not work in the Simulator.

## Architecture

The app uses AlarmKit for all alarm scheduling, countdown display, and alert delivery.

### Main App (`NapTime/`)

- **ContentView.swift** — Main UI. Displays an alarm duration grid (or an in-app countdown timer when an alarm is active). Schedules alarms via `AlarmManager.shared.schedule()` and listens to `alarmManager.alarmUpdates` for state changes. Includes a hidden debug mode (triple-tap the title) with short test durations.
- **NapTimeApp.swift** — Minimal `@main` entry point with a `WindowGroup`.
- **NapTimeMetadata.swift** — Shared struct conforming to `AlarmMetadata` protocol with a `durationLabel` property. Used by both the main app and widget extension.
- **StopAlarmIntent.swift** — `LiveActivityIntent` that cancels all active alarms. Used by the Lock Screen/Dynamic Island stop button and passed as `stopIntent` when scheduling.
- **alarm.wav** — Alarm sound file in the app bundle.

### Widget Extension (`NapTimeCountdown/`)

- **NapTimeCountdownLiveActivity.swift** — Live Activity widget for Lock Screen and Dynamic Island. Shows countdown timer with an inline stop button. Uses `AlarmAttributes<NapTimeMetadata>` and `AlarmPresentationState`.
- **NapTimeCountdownBundle.swift** — `@main` widget bundle entry point.

### Configuration

- **Info.plist** (project root) — Contains `NSAlarmKitUsageDescription`. Placed at the project root (not inside `NapTime/`) to avoid conflicts with the file system synchronized build phase.

## Key Patterns

- Alarm durations are defined in `alarmOptions` (production) and `debugAlarmOptions` (debug mode) arrays in ContentView.swift.
- `AlarmManager.shared` is the single point of contact for scheduling, canceling, and monitoring alarms.
- `NapTimeMetadata.swift` is shared between the app and widget extension via target membership exceptions in the project file.
- `StopAlarmIntent` is also shared between both targets for interactive stop buttons.
- Debug mode is toggled by triple-tapping the "NapTime Alarm" title — shows test durations (3s, 10s, 30s, 1m), authorization status, and alarm state info.
