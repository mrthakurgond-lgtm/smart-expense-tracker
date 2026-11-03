# Smart Expense Tracker

A Flutter student project for tracking income and expenses locally on an Android device.

## Features
- Splash, Login, Register, Dashboard, Add Transaction, History, Monthly Summary, Profile & Settings (8 screens)
- GetX named-route navigation
- SharedPreferences local persistence for transactions, display name and dark-mode preference
- Income/expense totals, category selection, monthly totals and category breakdown
- Material 3 UI and dark mode

## Tech stack
Flutter, Dart, GetX, SharedPreferences, intl, Material 3.

## Run locally
1. Install Flutter and Android Studio with Android SDK.
2. Open this folder in VS Code / Android Studio.
3. Run `flutter pub get`.
4. Start an Android emulator or connect an Android phone.
5. Run `flutter run`.

## Build release APK
Run `flutter build apk --release`. The APK is generated at:
`build/app/outputs/flutter-apk/app-release.apk`

## Important notes
- Login/Register in this academic demo stores a display name locally; it is not server-backed authentication.
- Data is stored on the same device using SharedPreferences and is not synced to a cloud account.
- This source package has not been built or device-tested in your environment. Resolve Android SDK/NDK and disk-space issues before claiming a tested APK.
- Add your actual group name and member names below before submission.

## Team
- Group name: [Enter group name]
- Member 1: [Enter name]
- Member 2: [Enter name]
