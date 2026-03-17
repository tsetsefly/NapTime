# App Store Readiness

Review of changes needed before submitting NapTime to the App Store.

## Must Fix

### 1. Widget extension missing app icons
`NapTimeCountdown/Assets.xcassets/AppIcon.appiconset/` has a Contents.json but no actual image files. The widget will show a blank icon. Add a 1024x1024 icon in Xcode.

**Status: TODO** — requires manual icon asset in Xcode.

### 2. Raw error messages shown to users
~~Several error messages dump technical info that users shouldn't see.~~

**Status: DONE** — all error messages now show user-friendly text.

### 3. Debug mode ships to production
~~Triple-tapping the title activates debug mode with test timers.~~

**Status: DONE** — all debug code gated behind `#if DEBUG`, stripped from Release builds.

## Should Fix

### 4. alarm.wav not referenced in code
~~The alarm sound file exists in the bundle but isn't used.~~

**Status: DONE** — re-enabled with `sound: .named("alarm")` in the schedule call.

### 5. Missing Privacy Manifest
~~Apple requires a `PrivacyInfo.xcprivacy` file for apps using certain APIs.~~

**Status: DONE** — added `PrivacyInfo.xcprivacy` declaring UserDefaults usage (reason: 1C8F.1 — app group shared data), no tracking, no collected data.

### 6. No CFBundleDisplayName set
~~The app's home screen name defaults to the target name.~~

**Status: DONE** — added `CFBundleDisplayName` = "NapTime" to Info.plist.

## Nice to Have

### 7. Empty test files
~~Boilerplate test files with no real assertions.~~

**Status: DONE** — stripped to minimal stubs.

### 8. Basic launch screen
Using SwiftUI's default launch screen — functional but no custom branding.

**Status: TODO** — optional cosmetic improvement.
