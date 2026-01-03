# Opening Project in Android Studio

## ✅ Android Studio Launched

The Android folder has been opened. Android Studio should be launching now.

## What to Expect

1. **Gradle Sync** - Android Studio will automatically sync Gradle (may take 1-2 minutes)
2. **Project Structure** - You'll see the Android project structure on the left
3. **Build Configuration** - The app is configured as "com.entrenous.quiz_app"

## Next Steps in Android Studio

### 1. Wait for Gradle Sync
- Look for "Gradle sync" progress at the bottom
- Wait until it says "Gradle sync finished"

### 2. Run the App

**Option A - On Emulator:**
1. Click **Device Manager** (phone icon on right sidebar)
2. Create a new device if needed (Pixel 6 recommended)
3. Start the emulator
4. Click the green **Run** button (▶️) at the top

**Option B - On Physical Device:**
1. Connect your Android phone via USB
2. Enable **Developer Options** and **USB Debugging** on phone
3. Select your device from the device dropdown
4. Click the green **Run** button (▶️)

### 3. Build APK

1. **Build** → **Build Bundle(s) / APK(s)** → **Build APK(s)**
2. Wait for build to complete
3. Click "locate" in the notification to find the APK

## Project Structure

```
android/
├── app/
│   ├── src/main/
│   │   ├── AndroidManifest.xml  (✅ Internet permission added)
│   │   ├── kotlin/              (MainActivity)
│   │   └── res/                 (Resources, icons)
│   └── build.gradle.kts         (✅ Configured)
└── build.gradle.kts
```

## Troubleshooting

### Gradle Sync Failed
- Click **File** → **Invalidate Caches** → **Invalidate and Restart**
- Or run in terminal: `cd android && ./gradlew clean`

### SDK Not Found
- **File** → **Settings** → **Appearance & Behavior** → **System Settings** → **Android SDK**
- Ensure Android SDK is installed

### Device Not Showing
- Check USB debugging is enabled
- Try: `adb devices` in terminal
- Restart ADB: `adb kill-server && adb start-server`

## Quick Commands (Alternative to Android Studio)

```bash
# From project root
cd C:\Users\naika\.gemini\antigravity\scratch\quiz_app

# Run on connected device
flutter run

# Build APK
flutter build apk --release

# Check devices
flutter devices
```

## App Details

- **Name**: Entre Nous Quiz
- **Package**: com.entrenous.quiz_app
- **Min SDK**: 21 (Android 5.0)
- **Features**: Supabase cloud sync, quiz system, admin panel
