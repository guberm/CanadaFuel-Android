# CanadaFuel 🇨🇦🍁

<p align="center">
  <img src="icon.png" width="200" alt="CanadaFuel Icon">
</p>

## Overview
A dynamic Android application built in Flutter that actively tracks and caches Canadian gas prices city-by-city. Redesigned to fetch data efficiently using a fast serverless AWS Lambda backend.

**Currently Supported Cities:** Toronto, Ottawa, Kitchener

## Key Features
- ⚡ **Serverless API**: Fast & reliable price data fetching via an AWS Lambda backend.
- 🔄 **Background Sync**: Hourly syncing via Android `WorkManager` ensures you always have the latest data without opening the app.
- 🔔 **Custom Alerts**: Real-time push notifications (`flutter_local_notifications`) alert you to price surges or drops. Custom time-pickers let you choose exactly when your phone checks.
- 📍 **Smart GPS Tracking**: Automatically defaults to your closest supported city upon first boot.
- ⭐️ **Favorites**: Star your primary city to always load it first.
- 🌙 **Native Theming**: Full seamless light and dark mode synchronization matching your device.

## Build Requirements
- Flutter SDK >= 3.2.0
- Dart SDK
- Android SDK 21+

*To regenerate the Android adaptive icons after modifying `icon.png`, run: `dart run flutter_launcher_icons`*
