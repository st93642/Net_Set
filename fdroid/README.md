# F-Droid Packaging Notes

F-Droid builds apps from source and signs them with the official F-Droid signing key.

## Dependencies / Proprietary checks

This app uses only open-source AndroidX/Jetpack Compose libraries and does **not** include Google Play Services, Firebase, analytics, ads, or crash reporting SDKs.

Gradle repositories used:

- `google()` (AndroidX/Compose artifacts)
- `mavenCentral()`

## Build variant

A dedicated `fdroid` build type is provided in `android/app/build.gradle`:

- It is based on `release`
- It is **unsigned** (`signingConfig null`)

Build locally:

```bash
cd android
./gradlew :app:assembleFdroid
```

## Metadata

`fdroid/com.net_set.app.yml` is a template intended for submission to the `fdroiddata` repository.

You will typically need to adjust:

- `Repo` / `SourceCode` URLs if the upstream changes
- The `commit` value for new versions (e.g., `v1.0.1`)
- Category selection if desired
