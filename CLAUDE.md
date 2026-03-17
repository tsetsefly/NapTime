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

The app uses AlarmKit for all alarm scheduling, countdown display, and alert delivery. See `docs/codebase-overview.md` for a detailed walkthrough of every file and the alarm lifecycle.

### Main App (`NapTime/`)

- **ContentView.swift** — Main UI with alarm duration grid and in-app countdown timer. Schedules alarms via `AlarmManager.shared.schedule()` and listens to `alarmManager.alarmUpdates` for state changes.
- **NapTimeApp.swift** — Minimal `@main` entry point.
- **NapTimeMetadata.swift** — Shared `AlarmMetadata` struct with `durationLabel` and `durationSeconds`. Used by both targets.
- **StopAlarmIntent.swift** — `LiveActivityIntent` that cancels all active alarms. Used by Lock Screen/Dynamic Island stop button.
- **RestartAlarmIntent.swift** — `LiveActivityIntent` that cancels and reschedules with the same duration. Reads/writes duration to App Group UserDefaults.
- **alarm.wav** — Custom alarm sound, referenced via `AlertConfiguration.AlertSound.named("alarm")`.
- **PrivacyInfo.xcprivacy** — Privacy manifest declaring UserDefaults API usage.
- **NapTime.entitlements** — App Group entitlement for sharing data with widget extension.

### Widget Extension (`NapTimeCountdown/`)

- **NapTimeCountdownLiveActivity.swift** — Live Activity for Lock Screen and Dynamic Island. Shows countdown, restart button (orange), and stop button (red).
- **NapTimeCountdownBundle.swift** — `@main` widget bundle entry point.
- **NapTimeCountdown.entitlements** — App Group entitlement matching the main app.

### Configuration

- **Info.plist** (project root) — Contains `NSAlarmKitUsageDescription` and `CFBundleDisplayName`. At project root (not inside `NapTime/`) to avoid conflicts with file system synchronized build phase.

## Key Patterns

- `AlarmManager.shared` is the single point of contact for scheduling, canceling, and monitoring alarms.
- Three files are shared between app and widget extension via target membership exceptions: `NapTimeMetadata.swift`, `StopAlarmIntent.swift`, `RestartAlarmIntent.swift`.
- App Group `group.tsetsefly.NapTime` enables shared UserDefaults between the app and widget extension (used by RestartAlarmIntent to persist last alarm duration).
- Debug mode (`#if DEBUG` only) is toggled by triple-tapping the title — shows test durations, authorization status, and alarm state.
- All user-facing error messages are friendly text; raw errors are not exposed.

## Docs

- `docs/codebase-overview.md` — Comprehensive context doc for resuming work on this project
- `docs/app-store-readiness.md` — Pre-submission checklist with status
- `docs/alarmkit-migration-plan.md` — Original migration plan from UNNotificationRequest to AlarmKit
- `docs/migration-status.md` — Migration phase tracker
- `docs/refactor-plan.md` — Post-migration cleanup tasks
