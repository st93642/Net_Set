# Net_Set Android App

This is a minimal Android application that wraps the Net_Set shell scripts for network configuration and diagnostics.

## Project Structure

```
android/
├── app/
│   ├── build.gradle                 # App-level build configuration
│   ├── proguard-rules.pro          # ProGuard rules
│   └── src/main/
│       ├── AndroidManifest.xml     # App manifest with INTERNET permission
│       ├── java/com/net_set/app/
│       │   ├── MainActivity.kt      # Main Activity
│       │   ├── utils/
│       │   │   └── ScriptManager.kt # Manages script copying and execution
│       │   └── ui/
│       │       ├── StatusScreen.kt  # Main UI with Jetpack Compose
│       │       └── theme/          # UI theme and colors
│       ├── res/                    # Resources (strings, themes, icons)
│       └── assets/                 # Bundled shell scripts
│           ├── net_set.sh          # Linux network configuration script
│           ├── network-verify.sh   # Network diagnostics script
│           └── net_set.ps1         # Windows PowerShell script
├── build.gradle                    # Project-level build configuration
├── gradle.properties              # Gradle configuration
├── settings.gradle               # Project settings
└── .gitignore                    # Git ignore rules
```

## Features

- **Simple Android UI**: Single Activity with Jetpack Compose showing status and controls
- **Script Bundling**: Shell scripts are included as app assets and copied to app data directory on first run
- **INTERNET Permission Only**: Minimal permissions for basic network access
- **Root Detection**: Attempts to run scripts as regular user first, then falls back to root if needed
- **Basic Error Handling**: Graceful handling of missing scripts or execution errors

## Architecture

The app follows a simple architecture:

1. **MainActivity** → Initializes the UI
2. **StatusScreen** → Jetpack Compose UI showing app status and controls
3. **ScriptManager** → Handles copying scripts from assets to app directory and executing them

## Scripts Included

- **net_set.sh**: Main network configuration script (Linux)
- **network-verify.sh**: Network diagnostics script (Linux)
- **net_set.ps1**: Windows PowerShell script (included for completeness)

## Building

To build this project, you need:

1. Android Studio or Android SDK
2. Gradle 8.2+
3. Kotlin 1.9.20+
4. Android SDK 35 (compileSdk)

```bash
./gradlew assembleDebug
```

## Running

The app can be installed on Android devices with:
- minSdk: 26 (Android 8.0)
- targetSdk: 35 (latest Android)

## Limitations

- Most features of the original scripts require root access to function properly
- The app provides a wrapper interface but the actual functionality depends on device capabilities
- Shell scripts are designed for Linux systems - Android compatibility varies by device

## Future Enhancements

This is Phase 1 of a larger Android port. Future phases may include:
- VPN-based DNS enforcement (VpnService)
- Native Android network diagnostics
- Root integration via libsu
- Advanced firewall controls
- Background services for continuous monitoring