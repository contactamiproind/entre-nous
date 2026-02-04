---
description: Build the Android APK for release
---

1. Clean the project to ensure a fresh build
   // turbo
   ```bash
   flutter clean
   ```

2. Get dependencies
   // turbo
   ```bash
   flutter pub get
   ```

3. Build the Release APK
   // turbo
   ```bash
   flutter build apk --release
   ```

4. Notify the user of the output location
   The APK will be located at `build/app/outputs/flutter-apk/app-release.apk`.
