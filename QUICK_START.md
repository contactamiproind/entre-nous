# Quick Start Guide

## ✅ Your App is Ready!

The Flutter quiz app has been successfully built and is running.

## Current Status

- ✅ **APK Built**: `build/app/outputs/flutter-apk/app-debug.apk`
- ✅ **Windows App**: Running now
- ✅ **Android Emulator**: Detected (emulator-5554)

## To Run on Android Emulator

The app is currently running on Windows. To run on Android emulator:

```bash
# Stop current app (press 'q' in terminal or Ctrl+C)
# Then run:
flutter run -d emulator-5554
```

## To Install APK on Physical Android Device

1. **Transfer APK** from `build/app/outputs/flutter-apk/app-debug.apk` to your phone
2. **Open APK** on phone to install
3. **Allow** installation from unknown sources if prompted

## Quick Commands

```bash
# Run on any available device
flutter run

# Run on specific device
flutter run -d windows          # Windows
flutter run -d emulator-5554    # Android emulator
flutter run -d chrome           # Web browser

# Build release APK
flutter build apk --release

# Check connected devices
flutter devices
```

## App Features

- 🎨 **Welcome Screen** with Entre Nous logo
- 🔐 **Login**: user/user123 or admin/admin123
- 📊 **User Dashboard** with progress tracking
- ❓ **Quiz System** with 5 levels
- 👨‍💼 **Admin Panel** for user management
- ☁️ **Cloud Sync** via Supabase

## Troubleshooting

**App not opening on emulator?**
- Make sure emulator is fully started
- Run: `flutter run -d emulator-5554`

**Want to run on physical device?**
- Enable USB debugging on phone
- Connect via USB
- Run: `flutter run`

**Need to rebuild?**
```bash
flutter clean
flutter pub get
flutter run
```
