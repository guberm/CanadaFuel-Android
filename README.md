# GasWizard App (Flutter)

An Android application that checks the `canadafuel.guber.dev` API and notifies you about gas price changes in the background.

## Features
- **Background Checks**: Uses `workmanager` to fetch API prices every hour even when closed.
- **Local Notifications**: Pushes an alert via `flutter_local_notifications` if the price changes.
- **Geolocation**: Automatically defaults to your geographically nearest city using `geolocator` if a default isn't selected.

## Getting Started

Because the initial codebase was scaffolded in an environment without the Flutter SDK, the platform-specific folders (`android/`, `ios/`) have not been generated yet.

To build the app, run the following commands on a machine with Flutter installed:

```bash
cd GasWizardApp
# Generate the platform folders and link the pubspec dependencies
flutter create .
# Run the app on your connected device or emulator
flutter run
```

## Permissions Needed
When you first run the app on Android, make sure to grant the following system permissions when prompted:
1. Location permissions (for finding the closest city).
2. Notification permissions (Android 13+ requires explicit opt-in for notifications).
