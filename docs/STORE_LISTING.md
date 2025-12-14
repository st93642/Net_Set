# Store Listing Assets (Net_Set Android)

This document contains prepared text assets for publishing on Google Play and F-Droid.

## App name

- **Net_Set** (or **Net_Set Android**, if a platform suffix is preferred)

## Short description

Simple network hardening tool for Android

## Full description

Net_Set is a simple, open-source network hardening and diagnostics tool for Android.

It provides a minimal status screen and a set of connectivity checks to help you validate your network environment:

- IPv4 and IPv6 connectivity tests
- DNS resolution tests (with selectable resolvers)
- Encrypted DNS (DNS-over-HTTPS) reachability checks

Where supported by your device, Net_Set can also run the bundled Net_Set scripts to apply network configuration changes. Some operations may require root access.

Privacy:
Net_Set does not collect data, does not run analytics, and does not include ads.

Source code:
https://github.com/st93642/Net_Set

## Privacy policy

See: `PRIVACY_POLICY.md`

## Screenshots

Recommended screenshots:

1. Main Status screen showing Applied Settings and Diagnostics
2. Diagnostics results (Pass/Fail list)
3. Script output section expanded (optional)

Suggested spec:

- Phone screenshots: PNG or JPEG
- At least 1080x1920

Fastlane screenshot directory:

- `android/fastlane/metadata/android/en-US/images/phoneScreenshots/`

## Release notes (1.0.0 / versionCode 1)

Initial release of Net_Set Android.

- Status screen showing applied settings
- Network diagnostics (IPv4/IPv6, DNS, DoH)
- Run bundled Net_Set scripts (device support varies; root may be required)
