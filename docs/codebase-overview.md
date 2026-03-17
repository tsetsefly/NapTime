# Codebase Overview

Comprehensive reference for getting up to speed on NapTime quickly.

## What This App Does

NapTime is a nap alarm app. The user picks a duration (10–60 minutes), the app schedules an AlarmKit alarm, and the system handles everything: Lock Screen countdown, Dynamic Island display, and a full-screen alert with sound when time is up. AlarmKit breaks through Silent Mode and Do Not Disturb.

## Project Structure

```
NapTime/
├── CLAUDE.md                           # Project guidance for Claude Code
├── Info.plist                          # App Info.plist (at root, not in NapTime/)
├── Assets.xcassets/                    # App icons (37 sizes)
├── NapTime/                            # Main app target
│   ├── NapTimeApp.swift                # @main entry point (10 lines)
│   ├── ContentView.swift               # All UI + alarm scheduling (~270 lines)
│   ├── NapTimeMetadata.swift           # AlarmMetadata struct (shared with widget)
│   ├── StopAlarmIntent.swift           # LiveActivityIntent: cancel alarm (shared)
│   ├── RestartAlarmIntent.swift        # LiveActivityIntent: restart alarm (shared)
│   ├── NapTime.entitlements            # App Group entitlement
│   ├── PrivacyInfo.xcprivacy           # Privacy manifest
│   └── alarm.wav                       # Custom alarm sound (4.8 MB)
├── NapTimeCountdown/                   # Widget extension target
│   ├── NapTimeCountdownBundle.swift    # @main widget bundle
│   ├── NapTimeCountdownLiveActivity.swift  # Live Activity UI (~107 lines)
│   ├── NapTimeCountdown.entitlements   # App Group entitlement
│   ├── Info.plist                      # Widget extension config
│   └── Assets.xcassets/                # Widget icon
├── NapTimeTests/                       # Empty test stubs
├── NapTimeUITests/                     # Empty test stubs
└── docs/                               # Documentation
```

## Targets & Configuration

| Target | Bundle ID | Deployment | Notes |
|---|---|---|---|
| NapTime | `tsetsefly.NapTime` | iOS 26.1 | Main app |
| NapTimeCountdownExtension | `tsetsefly.NapTime.NapTimeCountdown` | iOS 26.1 | Widget extension |
| NapTimeTests | `tsetsefly.NapTimeTests` | iOS 26.1 | Empty stubs |
| NapTimeUITests | `tsetsefly.NapTimeUITests` | iOS 26.1 | Empty stubs |

**App Group:** `group.tsetsefly.NapTime` (both app and widget extension)

**Info.plist note:** The main app's Info.plist lives at the project root (not inside `NapTime/`) because the `NapTime/` folder uses Xcode's file system synchronized build phase. Placing it inside would cause a "multiple commands produce Info.plist" build error.

## File-by-File Guide

### ContentView.swift (the core of the app)

This is where almost all logic lives. Key sections:

**Data:**
- `alarmOptions` — production durations: 10m, 13m, 15m, 20m, 23m, 25m, 45m, 60m
- `debugAlarmOptions` — test durations: 3s, 10s, 30s, 1m (only in `#if DEBUG`)

**State:**
- `authorizationState` — AlarmKit permission status
- `activeAlarm` — currently scheduled `Alarm` object (nil when no alarm)
- `alarmFireDate` — when the alarm will fire (for in-app countdown display)
- `errorMessage` — user-facing error text
- `debugMode` — toggle for debug UI (`#if DEBUG` only)

**UI flow:**
- No alarm active → shows 2-column grid of duration buttons
- Alarm active + fire date in future → shows large countdown timer + stop button
- Alarm active + fire date in past → falls back to button grid (prevents crash from invalid date range)

**Key functions:**
- `requestAuthorization()` — called on launch, requests AlarmKit permission
- `scheduleAlarm(seconds:label:)` — cancels existing alarm, creates `AlarmAttributes<NapTimeMetadata>` with presentation config, schedules via `AlarmManager.shared.schedule()`, saves duration for restart
- `cancelAlarm()` — calls `alarmManager.cancel(id:)` (synchronous, not async)

**On launch (`.task` modifiers):**
1. Requests authorization
2. Cancels any leftover alarms from previous runs
3. Starts listening to `alarmManager.alarmUpdates` async stream

### NapTimeMetadata.swift

```swift
nonisolated struct NapTimeMetadata: AlarmMetadata {
    var durationLabel: String    // e.g. "10 minutes"
    var durationSeconds: Int     // e.g. 600
}
```

Shared between app and widget. `durationSeconds` is used by `RestartAlarmIntent` to know how long to reschedule.

### StopAlarmIntent.swift

`LiveActivityIntent` that cancels all active alarms. Used in two places:
1. Passed as `stopIntent` when scheduling (system uses it for the alarm alert's stop button)
2. Referenced directly in the Live Activity UI as a `Button(intent:)` action

### RestartAlarmIntent.swift

`LiveActivityIntent` that cancels the current alarm and reschedules with the same duration. Uses App Group `UserDefaults` to persist the last alarm's `durationSeconds` and `durationLabel`, since `Alarm` objects don't expose metadata back to the caller.

**Flow:** `saveLastAlarm()` is called in ContentView when scheduling → `perform()` reads from UserDefaults, cancels, and reschedules.

### NapTimeCountdownLiveActivity.swift

The widget extension's Live Activity. Three display contexts:

**Lock Screen / Banner:**
- HStack: "NapTime" + countdown on left, restart (orange) + stop (red) buttons on right
- Only shows buttons during `.countdown` state

**Dynamic Island Expanded:**
- Leading: "NapTime" label
- Trailing: countdown text
- Bottom: progress ring + restart + stop buttons

**Dynamic Island Compact/Minimal:**
- Compact leading: alarm icon
- Compact trailing: countdown text
- Minimal: alarm icon

**Helper views:**
- `CountdownTextView` — renders `Text(timerInterval: Date.now ... fireDate)` for auto-updating countdown
- `CountdownProgressView` — circular `ProgressView` with timer interval

## Alarm Lifecycle

```
User taps "20 minutes"
    ↓
ContentView.scheduleAlarm(seconds: 1200, label: "20 minutes")
    ↓
Cancel any existing alarm
    ↓
Create AlarmPresentation (alert title + countdown title)
Create NapTimeMetadata (label + seconds)
Create AlarmAttributes (presentation + metadata + tint color)
    ↓
AlarmManager.shared.schedule(id: UUID(), config: .timer(...))
    ↓
System activates Live Activity on Lock Screen / Dynamic Island
    ↓
NapTimeCountdownLiveActivity renders countdown + buttons
    ↓
User can:
  • Stop (StopAlarmIntent) → cancels alarm, Live Activity ends
  • Restart (RestartAlarmIntent) → cancels + reschedules same duration
  • Wait for alarm to fire → system shows full-screen alert + plays alarm.wav
```

## Shared Code Between Targets

Three files have target membership in both the main app and widget extension (configured via `PBXFileSystemSynchronizedBuildFileExceptionSet` in the pbxproj):

1. `NapTimeMetadata.swift` — alarm metadata type
2. `StopAlarmIntent.swift` — stop button action
3. `RestartAlarmIntent.swift` — restart button action

## AlarmKit API Usage

| API | Where Used | Notes |
|---|---|---|
| `AlarmManager.shared` | ContentView | Singleton for all alarm operations |
| `.schedule(id:configuration:)` | ContentView | Async throwing, returns `Alarm` |
| `.cancel(id:)` | ContentView, StopAlarmIntent | Synchronous throwing (not async) |
| `.alarms` | ContentView, StopAlarmIntent | Throwing property, returns `[Alarm]` |
| `.alarmUpdates` | ContentView | AsyncSequence of `[Alarm]` |
| `.requestAuthorization()` | ContentView | Async throwing, returns `AuthorizationState` |
| `.authorizationState` | ContentView | Synchronous property |
| `AlarmAttributes<NapTimeMetadata>` | ContentView, RestartAlarmIntent, Live Activity | Generic over app's metadata type |
| `AlarmPresentation.Alert` | ContentView, RestartAlarmIntent | `init(title:)` — system provides stop button |
| `AlarmPresentation.Countdown` | ContentView, RestartAlarmIntent | `init(title:)` — shown during countdown |
| `AlarmPresentationState` | Live Activity | System-managed content state |
| `AlertConfiguration.AlertSound.named()` | ContentView, RestartAlarmIntent | References `alarm.wav` in bundle |

## Debug Mode

Only available in Debug builds (`#if DEBUG`). Activated by triple-tapping the "NapTime Alarm" title.

Shows:
- Test alarm buttons (3s, 10s, 30s, 1m) in orange
- Authorization state text
- "DEBUG MODE" badge
- Active alarm ID and state

## Known Considerations

- **Physical device required** — AlarmKit does not work in the iOS Simulator
- **`cancel(id:)` is synchronous** — unlike `schedule()` which is async, `cancel()` is a synchronous throwing function
- **`alarmManager.alarms` is a throwing property** — must be accessed with `try`
- **Countdown crash guard** — `Text(timerInterval:)` crashes if `fireDate` is in the past, so the countdown display checks `fireDate > Date.now`
- **Info.plist at project root** — must stay outside the `NapTime/` synced folder to avoid duplicate plist build errors
- **`AlarmPresentation.Alert` deprecated init** — the `init(title:stopButton:)` variant is deprecated; use `init(title:)` (iOS 26.1+, system provides stop button automatically)
