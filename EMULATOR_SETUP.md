# Connect Flutter App to Android Emulator

## Quick Start - Launch Emulator and Run App

### Method 1: Using Android Studio (Recommended)

1. **Open Android Studio**
2. **Click "Device Manager"** (phone icon on the right toolbar)
3. **Start an emulator** by clicking the ▶️ play button next to any device
4. **Wait for emulator to fully boot** (you'll see the Android home screen)
5. **Run the app:**
   ```bash
   cd C:\Users\naika\.gemini\antigravity\scratch\quiz_app
   flutter run
   ```

### Method 2: Using Command Line

1. **List available emulators:**
   ```bash
   flutter emulators
   ```

2. **Launch an emulator** (replace with your emulator ID):
   ```bash
   flutter emulators --launch <emulator-id>
   ```
   
   Example emulator IDs you might have:
   - `Pixel_3a_API_34_extension_level_7_x86_64`
   - `Pixel_8_API_35`
   - `Medium_Phone_API_35`

3. **Wait 30-60 seconds** for emulator to boot completely

4. **Verify emulator is running:**
   ```bash
   flutter devices
   ```
   You should see an Android emulator in the list.

5. **Run your app:**
   ```bash
   flutter run
   ```

## Troubleshooting

### Emulator Won't Launch

**Option A: Launch from Android Studio**
- Open Android Studio → Tools → Device Manager → Click ▶️ on any device

**Option B: Find Android SDK path and launch manually**
```bash
# Find where Android SDK is installed
where emulator

# Or check common locations:
# C:\Users\<username>\AppData\Local\Android\Sdk\emulator\emulator.exe
# C:\Program Files\Android\Android Studio\emulator\emulator.exe
```

### "Lost Connection to Device" Error

This was an issue in your previous sessions. To avoid it:

1. **Ensure emulator is fully booted** before running `flutter run`
2. **Use a stable emulator** (Pixel 3a or Pixel 8 recommended)
3. **Increase emulator RAM** in Android Studio:
   - Device Manager → ⚙️ Edit → Advanced Settings → RAM: 2048 MB or higher

4. **Cold boot the emulator:**
   - Device Manager → ⋮ (three dots) → Cold Boot Now

### No Devices Found

```bash
# Check if emulator is running
flutter devices

# If no devices, restart ADB
flutter doctor

# Or manually find and start emulator from Android Studio
```

### Emulator is Slow

1. **Enable Hardware Acceleration:**
   - Ensure Intel HAXM or AMD Hypervisor is installed
   - Android Studio → SDK Manager → SDK Tools → Intel x86 Emulator Accelerator (HAXM)

2. **Use a lighter emulator:**
   - Create a new device with lower resolution
   - Reduce RAM allocation if your PC has limited memory

## Running the App

Once emulator is running and visible in `flutter devices`:

```bash
# Run in debug mode (default)
flutter run

# Run with hot reload enabled
flutter run --hot

# Run on specific device if multiple are connected
flutter run -d <device-id>

# Example:
flutter run -d emulator-5554
```

## Expected Behavior

When successfully connected:
1. Flutter will compile the app (may take 1-2 minutes first time)
2. App will install on the emulator
3. App will launch automatically
4. You'll see "ENEPL App" with the Entre Nous Quiz interface
5. You can log in with: **user** / **user123**

## Quick Commands Reference

```bash
# List emulators
flutter emulators

# List connected devices
flutter devices

# Launch emulator
flutter emulators --launch <emulator-id>

# Run app
flutter run

# Hot reload (while app is running, press 'r' in terminal)
# Hot restart (press 'R')
# Quit (press 'q')
```

## Alternative: Run on Physical Android Device

If emulator issues persist:

1. **Enable Developer Options** on your Android phone
2. **Enable USB Debugging**
3. **Connect phone via USB**
4. **Run:** `flutter devices` (should show your phone)
5. **Run:** `flutter run`

## Next Steps

After successfully running on emulator:
- Test login functionality
- Test quiz flow
- Verify Supabase connection
- Check admin panel access
- Test progress tracking

For more details, see [ANDROID_BUILD.md](ANDROID_BUILD.md)
