# Publishing (Google Play, F-Droid, GitHub Releases)

This repository contains an Android app under `android/`.

## 1) Prepare signing for Play Store

Google Play requires a non-debug signing key.

1. Create a keystore (example):

   ```bash
   keytool -genkeypair -v \
     -keystore net_set-release.jks \
     -keyalg RSA -keysize 2048 -validity 10000 \
     -alias net_set
   ```

2. Create `android/keystore.properties` (do **not** commit it):

   ```properties
   storeFile=../net_set-release.jks
   storePassword=YOUR_STORE_PASSWORD
   keyAlias=net_set
   keyPassword=YOUR_KEY_PASSWORD
   ```

3. Build a Play Store bundle:

   ```bash
   cd android
   ./gradlew :app:bundleRelease
   ```

Output:
- `android/app/build/outputs/bundle/release/app-release.aab`

## 2) Google Play Store listing assets

Text metadata is in:

- `android/fastlane/metadata/android/en-US/`

A privacy policy is in:

- `PRIVACY_POLICY.md`

Screenshots:

- Use an emulator or physical device and capture the Status screen.
- Place 1080x1920 (or similar) PNG screenshots under:
  - `android/fastlane/metadata/android/en-US/images/phoneScreenshots/`

Release notes (for versionCode 1):

- `android/fastlane/metadata/android/en-US/changelogs/1.txt`

Manual submission steps (high level):

1. Create the app in Play Console (app name: **Net_Set**)
2. Complete Data safety (declare **no data collected**)
3. Upload the `app-release.aab`
4. Attach screenshots and listing text
5. Roll out to internal testing → production

## 3) F-Droid preparation

F-Droid builds from source and signs with F-Droid’s key.

- A dedicated `fdroid` build type is included to ensure the build is **unsigned**.

Build locally (unsigned):

```bash
cd android
./gradlew :app:assembleFdroid
```

Output:
- `android/app/build/outputs/apk/fdroid/` (APK filename may include `-unsigned`)

F-Droid metadata (for submitting to the `fdroiddata` repo) is provided as a starting point:

- `fdroid/com.net_set.app.yml`

## 4) GitHub release (manual)

1. Build your preferred artifact(s):
   - Play: `bundleRelease` (AAB)
   - GitHub: `assembleRelease` (APK) or `assembleFdroid` (unsigned APK)

2. Create a Git tag matching the app version (example):

```bash
git tag -a v1.0.0 -m "Net_Set Android 1.0.0"
git push origin v1.0.0
```

3. Create a GitHub release for the tag and attach:

- `app-release.aab` (Play submission artifact)
- `app-release.apk` (if you distribute APK outside Play)

4. Use the changelog as release notes:

- `CHANGELOG.md`

## 5) Links

- Privacy Policy: `PRIVACY_POLICY.md`
- Store listing text: `android/fastlane/metadata/android/en-US/`
- F-Droid metadata template: `fdroid/com.net_set.app.yml`
