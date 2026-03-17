# App Store Readiness

Review of changes needed before submitting NapTime to the App Store.

## Must Fix

### 1. Widget extension missing app icons
`NapTimeCountdown/Assets.xcassets/AppIcon.appiconset/` has a Contents.json but no actual image files. The widget will show a blank icon.

### 2. Raw error messages shown to users
Several error messages dump technical info that users shouldn't see:
- `"Auth failed: \(error)"` (ContentView.swift:188)
- `"Schedule failed (auth: \(alarmManager.authorizationState)): \(error)"` (ContentView.swift:226)

These should show user-friendly messages by default and only show verbose output in debug mode.

### 3. Debug mode ships to production
Triple-tapping the title activates debug mode with test timers (3s, 10s, 30s, 1m), authorization status, and alarm state info. This should be gated behind `#if DEBUG` so it's stripped from Release builds.

## Should Fix

### 4. alarm.wav not referenced in code
The alarm sound file exists in the bundle but isn't used — the custom sound reference was removed during debugging. Either wire it back up with `AlertConfiguration.AlertSound.named("alarm")` or remove the 4.6 MB file from the bundle.

### 5. Missing Privacy Manifest
Apple requires a `PrivacyInfo.xcprivacy` file for apps using certain APIs. NapTime uses UserDefaults with App Groups, which is a declared API type. Create a privacy manifest for the main app target.

### 6. No CFBundleDisplayName set
The app's home screen name defaults to the target name. Add an explicit `CFBundleDisplayName` to Info.plist for clarity (e.g., "NapTime").

## Nice to Have

### 7. Empty test files
`NapTimeTests/` and `NapTimeUITests/` contain only Xcode-generated boilerplate with no real assertions. Consider removing or writing actual tests.

### 8. Basic launch screen
Using SwiftUI's default launch screen — functional but no custom branding.
