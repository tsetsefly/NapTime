# AlarmKit Migration Status

## Prerequisite
- **Xcode 26 beta required** — AlarmKit is not available in Xcode 16.3 (iOS 18.4 SDK). Install from https://developer.apple.com/download/

## Completed Phases

### Phase 1: Project Setup
- [x] Deployment target raised to iOS 26.0 (all targets)
- [x] `NSAlarmKitUsageDescription` added to NapTime build settings
- [x] Widget Extension target created (`NapTimeCountdownExtension`)
- [x] `NapTimeMetadata.swift` target membership set for both app and widget extension

### Phase 2: Alarm Data Model
- [x] `NapTime/NapTimeMetadata.swift` created — conforms to `AlarmMetadata`, has `durationLabel` property

### Phase 3: Alarm Scheduling (Main App)
- [x] `ContentView.swift` rewritten with AlarmKit (`AlarmManager.schedule`, `alarmUpdates`, authorization)
- [x] `NapTimeApp.swift` simplified (no `NotificationDelegate`)
- [x] Deleted `AlarmSoundManager.swift`, `NotificationDelegate.swift`, `CountdownManager.swift`

### Phase 4: Live Activity (Widget Extension)
- [x] `NapTimeCountdownLiveActivity.swift` rewritten with `AlarmAttributes<NapTimeMetadata>`, countdown text + progress views
- [x] `NapTimeCountdownBundle.swift` simplified (Live Activity only)
- [x] Deleted template files (`NapTimeCountdown.swift`, `NapTimeCountdownControl.swift`, `AppIntent.swift`)

## Remaining Work (After Xcode 26 Beta Installed)

### Build & Fix
- [ ] Build the project in Xcode 26 beta and fix any compiler errors
- [ ] AlarmKit API signatures may differ slightly from third-party docs — adjust as needed
- [ ] Verify `AlarmConfiguration.AlertSound.named("alarm")` works with the existing `alarm.wav`
- [ ] Test on a physical device (AlarmKit may not work in Simulator)

### Phase 5: Optional Enhancements
- [ ] Add secondary button with AppIntent to open app from alarm alert
- [ ] Add snooze support via `AlarmManager.shared.snooze(id:duration:)`
- [ ] Consider scheduled (date-based) alarms in addition to countdown timers

### Phase 6: Final Cleanup
- [ ] Update `CLAUDE.md` to reflect new architecture
- [ ] Remove any remaining unused code
- [ ] Test full alarm lifecycle: schedule → countdown on Lock Screen → alarm fires → stop
