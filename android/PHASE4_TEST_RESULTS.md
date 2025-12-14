# Phase 4 – Local Testing & Release APK Build (v1.0.0)

This document captures the Phase 4 manual test matrix and build instructions/results for the Net_Set Android wrapper app.

## Version / Packaging

- App module: `android/app`
- `versionName`: **1.0.0**
- `versionCode`: 1
- Release signing: **enabled** (release build uses the `debug` signing config for internal/testing releases).

> Note: For a production release, replace the release signing config with a real keystore loaded from CI secrets / environment variables.

## Release APK Build

### Commands

From the `android/` directory:

```bash
# Debug
./gradlew :app:assembleDebug

# Signed release APK
./gradlew :app:assembleRelease
```

### Output locations

- Debug APK: `android/app/build/outputs/apk/debug/app-debug.apk`
- Release APK: `android/app/build/outputs/apk/release/app-release.apk`

### Install via adb

```bash
adb install -r android/app/build/outputs/apk/release/app-release.apk
```

## Manual Test Matrix

Test on emulators/devices with working internet access.

### Devices / OS versions

- Emulator API 26 (Android 8.0)
- Emulator API 29 (Android 10)
- Emulator API 34 (Android 14)
- Physical device (if available)

### Smoke test (all devices)

1. Install the APK.
2. Launch **Net_Set Android**.
3. Verify:
   - No crash on launch.
   - The app auto-runs the “on launch” configuration attempt and shows output.
   - UI is responsive (buttons, scrolling, etc.).

### Settings verification (best-effort / expected limitations)

Because Android restricts system DNS and low-level sysctl changes for normal apps, “settings applied” is best-effort:

- **IPv6 status**: read from `/proc/sys/net/ipv6/conf/all/disable_ipv6` (may be inaccessible on some devices; should fail gracefully).
- **Current DNS**: best-effort read from `/etc/resolv.conf` (often not available on modern Android; app falls back to selected provider).

### Diagnostics verification

Run **Run Diagnostics** and verify:

- **IPv4 connectivity**: PASS if a TCP connection to `1.1.1.1:443` succeeds within 3s.
- **IPv6 connectivity**: PASS if a TCP connection to `2606:4700:4700::1111:443` succeeds within 3s.
- **DNS resolution**: PASS if `cloudflare.com` resolves via the system resolver.
- **Encrypted DNS (DoH)**: PASS if an HTTPS DoH request to the selected provider returns a valid JSON response with at least one answer.
  - Cloudflare: `https://cloudflare-dns.com/dns-query`
  - Quad9: `https://dns.quad9.net/dns-query`
  - Google: `https://dns.google/dns-query`

All failures must be **graceful** (FAIL result, no crash / hang).

## Results

Fill out during local testing:

| Target | Install | Launch | IPv4 | IPv6 | DNS | DoH | Notes |
|---|---:|---:|---:|---:|---:|---:|---|
| Emulator API 26 | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | |
| Emulator API 29 | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | |
| Emulator API 34 | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | |
| Physical device | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | |
