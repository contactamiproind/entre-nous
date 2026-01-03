# Android Build Guide

## ✅ Android Configuration Complete

Your Flutter quiz app is now configured for Android with:
- **Internet permission** for Supabase connectivity
- **App name**: "Entre Nous Quiz"
- **Package**: com.entrenous.quiz_app
- **Minimum SDK**: Android 5.0 (API 21)

## Build Options

### Option 1: Build APK (Recommended for Testing)

```bash
cd C:\Users\naika\.gemini\antigravity\scratch\quiz_app

# Debug APK (for testing)
flutter build apk --debug

# Release APK (for distribution)
flutter build apk --release
```

APK location: `build/app/outputs/flutter-apk/app-debug.apk`

### Option 2: Run on Connected Device/Emulator

```bash
# Check available devices
flutter devices

# Run on connected Android device
flutter run

# Run on specific device
flutter run -d <device-id>
```

### Option 3: Open in Android Studio

1. Open Android Studio
2. File → Open → Select `C:\Users\naika\.gemini\antigravity\scratch\quiz_app\android`
3. Wait for Gradle sync
4. Click Run (green play button)

## Android Emulator Setup

If you don't have a physical device:

1. **Open Android Studio**
2. **Tools** → **Device Manager**
3. **Create Device** → Select a phone (e.g., Pixel 6)
4. **Download** a system image (e.g., Android 13)
5. **Finish** and start the emulator
6. Run `flutter run` in terminal

## Install APK on Device

### Via USB:
1. Enable **Developer Options** on Android device
2. Enable **USB Debugging**
3. Connect device via USB
4. Run: `flutter install`

### Via File Transfer:
1. Build APK: `flutter build apk --release`
2. Copy APK from `build/app/outputs/flutter-apk/` to device
3. Open APK on device to install
4. Allow "Install from Unknown Sources" if prompted

## Testing Checklist

Once running on Android:
- [ ] App launches with Entre Nous logo
- [ ] Login works (user/user123)
- [ ] Supabase connection successful
- [ ] Quiz functionality works
- [ ] Progress saves to cloud
- [ ] Admin panel accessible

## Troubleshooting

### Gradle Build Failed
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
flutter build apk
```

### Device Not Detected
```bash
# Check ADB
adb devices

# Restart ADB
adb kill-server
adb start-server
```

### Internet Permission Error
- Already added to `AndroidManifest.xml`
- Rebuild if you see network errors

## App Signing (For Production)

To publish on Google Play Store, you'll need to sign the app:

1. Generate keystore
2. Update `android/key.properties`
3. Build signed APK: `flutter build apk --release`

See: https://docs.flutter.dev/deployment/android

## Next Steps

- Test on real Android device
- Customize app icon (in `android/app/src/main/res/mipmap-*/`)
- Add splash screen
- Prepare for Play Store release
