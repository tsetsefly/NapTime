# Refactor Plan

Post-AlarmKit migration cleanup to simplify the codebase and bring documentation in sync.

## 1. Update CLAUDE.md

The current CLAUDE.md describes the **old** pre-migration architecture (CountdownManager, AlarmSoundManager, NotificationDelegate, UNNotificationRequest, Timer.publish, silent mode alerts). All of that has been deleted. Rewrite to reflect:

- AlarmKit-based architecture (AlarmManager, AlarmAttributes, AlarmPresentation)
- Current file list: ContentView.swift, NapTimeApp.swift, NapTimeMetadata.swift, StopAlarmIntent.swift
- Widget extension: NapTimeCountdownLiveActivity.swift, NapTimeCountdownBundle.swift
- Info.plist at project root with NSAlarmKitUsageDescription
- iOS 26.1 minimum deployment target
- Debug mode (triple-tap title)

## 2. Remove unused import

`ContentView.swift` imports `ActivityKit` but doesn't use any ActivityKit types directly. AlarmKit re-exports what it needs. Remove the import.

## 3. Clean up error messages

The error messages mix debug-style output with user-facing text:

- `"Auth failed: \(error)"` — debug style
- `"Alarms not authorized (state: \(authorizationState))"` — debug style
- `"Schedule failed (auth: \(alarmManager.authorizationState)): \(error)"` — debug style
- `"Failed to request alarm permission: \(error.localizedDescription)"` — user-facing style

Standardize: show user-friendly messages by default, show verbose debug info only in debug mode.

## 4. Improve StopAlarmIntent error handling

`StopAlarmIntent.perform()` silently swallows all errors with `try?`. If cancellation fails, the user gets no feedback and the alarm keeps running. Should propagate errors so the system can report failure.

## 5. Update migration docs

`docs/migration-status.md` lists remaining tasks that are now done:
- "Build the project in Xcode 26 beta and fix any compiler errors" — done
- "AlarmKit API signatures may differ slightly" — resolved
- "Update CLAUDE.md to reflect new architecture" — will be done in item 1

Mark completed items and close out the migration tracker.

## 6. Remove empty test placeholders

`NapTimeTests/NapTimeTests.swift`, `NapTimeUITests/NapTimeUITests.swift`, and `NapTimeUITests/NapTimeUITestsLaunchTests.swift` contain only Xcode-generated boilerplate with no real assertions. They add noise without value. Remove the placeholder code and leave a single minimal test file, or delete the test files entirely until real tests are written.

## 7. Commit Xcode shared schemes

`NapTime.xcodeproj/xcshareddata/` contains scheme files that are currently untracked. These should be committed so the project builds correctly when cloned.
