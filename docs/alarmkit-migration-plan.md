# AlarmKit Migration Plan

## Context

NapTime currently uses `UNNotificationRequest` for alarm scheduling and `AVAudioPlayer` for alarm sound playback. This required several workarounds:
- Manual countdown tracking via `CountdownManager` with a 1-second `Timer.publish`
- `AlarmSoundManager` singleton to loop alarm audio via `AVAudioPlayer`
- `NotificationDelegate` to handle foreground vs background notification delivery and prevent double-playing sounds
- Two-step alert flows to warn users about Silent Mode / Do Not Disturb (alarms can't break through)
- No Lock Screen, Dynamic Island, or Apple Watch presence

AlarmKit (iOS 26+) makes all of this native. Alarms break through Silent Mode and DND, display on the Lock Screen / Dynamic Island / StandBy / Apple Watch, and the system handles sound playback.

## Requirements

- **Minimum deployment target**: iOS 26
- **New Info.plist key**: `NSAlarmKitUsageDescription`
- **New target**: Widget Extension for Live Activity (required for countdown display)
- **New dependency**: AppIntents framework (for custom alarm actions)

## What Gets Removed

These workarounds become unnecessary with AlarmKit:

| Current File | Why It's Removed |
|---|---|
| `AlarmSoundManager.swift` | System handles alarm sound playback |
| `NotificationDelegate.swift` | No more `UNNotificationRequest`-based alarms; no foreground/background split logic |
| `CountdownManager.swift` | Live Activity handles countdown display; AlarmManager tracks alarm state |
| Silent Mode / DND warning alerts | AlarmKit breaks through both automatically |

## What Changes

| Current | AlarmKit Equivalent |
|---|---|
| `UNNotificationRequest` scheduling | `AlarmManager.shared.schedule(id:configuration:)` |
| `Timer.publish` + `CountdownManager` | Live Activity countdown on Lock Screen / Dynamic Island |
| `AVAudioPlayer` looping | `AlertConfiguration.AlertSound.named("alarm")` |
| Manual permission request for notifications | `AlarmManager.shared.requestAuthorization()` |
| `alarmTriggered` state + "Wake up!!!" text | `AlarmPresentation.Alert` with system-provided full-screen alert |

## Migration Steps

### Phase 1: Project Setup

1. **Raise deployment target** to iOS 26 in Xcode project settings
2. **Add `NSAlarmKitUsageDescription`** to Info.plist (e.g., "NapTime uses alarms to wake you up after your nap.")
3. **Create a Widget Extension target** in Xcode (File > New > Target > Widget Extension)
   - Name it something like `NapTimeCountdown`
   - This will hold the Live Activity UI for countdown display
4. **Create a `Shared/` group** for code shared between the main app and the widget extension (e.g., alarm metadata, alarm identifiers)

### Phase 2: Define Alarm Data Model

5. **Create `AlarmMetadata`** — a struct conforming to `AlarmMetadata` protocol in `Shared/`
   - Include any custom data needed (e.g., the selected duration label)
   - This gets passed between the app and the Live Activity

6. **Create `AlarmAttributes`** using `AlarmAttributes<YourMetadata>`
   - Configure `AlarmPresentation` with:
     - `.alert`: title ("Time to wake up!"), stop button, optional secondary button
     - Tint color for visual identity

### Phase 3: Implement Alarm Scheduling (Main App)

7. **Replace `scheduleAlarm(in:)` in ContentView** with AlarmKit scheduling:
   ```swift
   import AlarmKit

   func scheduleAlarm(in seconds: Int) {
       let id = UUID()
       let stopButton = AlarmButton(text: "Stop", textColor: .white, systemImageName: "stop.circle")
       let alertPresentation = AlarmPresentation.Alert(title: "⏰ Time to wake up!", stopButton: stopButton)
       let presentation = AlarmPresentation(alert: alertPresentation)
       let attributes = AlarmAttributes<NapTimeMetadata>(presentation: presentation, tintColor: .blue)
       let sound = AlertConfiguration.AlertSound.named("alarm")
       let config = AlarmConfiguration(
           countdownDuration: TimeInterval(seconds),
           attributes: attributes,
           sound: sound
       )
       try await AlarmManager.shared.schedule(id: id, configuration: config)
   }
   ```

8. **Replace notification permission request** with AlarmKit authorization:
   ```swift
   let state = try await AlarmManager.shared.requestAuthorization()
   ```

9. **Replace `stopCountdown()`** with:
   ```swift
   AlarmManager.shared.cancel(id: alarmID)
   ```

### Phase 4: Implement Live Activity (Widget Extension)

10. **Implement the countdown Live Activity** in the widget extension target
    - Show remaining time on Lock Screen and Dynamic Island
    - Handle three states: `.countdown`, `.paused`, `.alert`
    - The system provides alarm state through the Live Activity context

11. **Configure the widget extension entitlements** if needed

### Phase 5: Optional Enhancements

12. **Add a secondary button** with an AppIntent to open the app from the alarm alert
    ```swift
    struct OpenNapTimeIntent: LiveActivityIntent {
        static var openAppWhenRun = true
        // ...
    }
    ```

13. **Add snooze support** — AlarmKit has built-in snooze via `AlarmManager.shared.snooze(id:duration:)`

14. **Consider adding scheduled (date-based) alarms** in addition to countdown timers, since AlarmKit supports both via `Alarm.Schedule.fixed()` and `Alarm.Schedule.Relative`

### Phase 6: Cleanup

15. **Delete `AlarmSoundManager.swift`** — no longer needed
16. **Delete `NotificationDelegate.swift`** — no longer needed
17. **Delete `CountdownManager.swift`** — no longer needed
18. **Remove the silent mode / DND warning alerts** from ContentView — AlarmKit breaks through both
19. **Remove `import UserNotifications`** from ContentView and NapTimeApp
20. **Remove the `UNUserNotificationCenter.current().delegate` setup** from NapTimeApp.init
21. **Simplify ContentView** — the grid of alarm buttons stays, but most of the state management and alert logic goes away

## New Project Structure (Approximate)

```
NapTime/
├── NapTime/
│   ├── NapTimeApp.swift          (simplified — no NotificationDelegate)
│   ├── ContentView.swift         (simplified — just buttons + AlarmKit calls)
│   └── alarm.wav                 (kept — referenced by AlarmKit sound config)
├── Shared/
│   ├── NapTimeMetadata.swift     (AlarmMetadata conformance)
│   └── AlarmIdentifiers.swift    (shared alarm ID management)
├── NapTimeCountdown/             (new Widget Extension target)
│   └── NapTimeCountdownLiveActivity.swift
├── Assets.xcassets/
└── NapTime.xcodeproj/
```

## Risks & Considerations

- **iOS 26 minimum** — drops support for all earlier iOS versions. If you need backward compatibility, you'd need `#available` checks and keep the old code path.
- **Widget Extension complexity** — Live Activities require a separate target and WidgetKit knowledge. This is the most complex part of the migration.
- **alarm.wav format** — verify the existing WAV file works with AlarmKit's `AlertSound.named()`. It should, as long as it's in the app bundle.
- **No detection of alarm dismissal** — AlarmKit currently doesn't call the stop intent when users swipe away an alarm (known limitation).
- **Testing** — AlarmKit alarms may only work on physical devices, not in the Simulator (verify during development).
