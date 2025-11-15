# Network Configuration UI - Desktop Wrappers

This directory contains desktop UI wrappers for the network configuration scripts, providing user-friendly graphical interfaces for both Linux and Windows platforms.

## 🖥️ UI Wrapper Files

### Linux Version
- **`net_set_ui.sh`** - Main UI wrapper script with GUI (zenity) and terminal fallback
- **`build_linux.sh`** - Build script to create standalone Linux executable

### Windows Version
- **`net_set_ui.ps1`** - Main UI wrapper script with Windows Forms GUI
- **`build_windows.ps1`** - Build script to create standalone Windows executable

## 🚀 Quick Start

### For Linux Users

#### Option 1: Run Directly (Recommended for development)
```bash
# Make the script executable
chmod +x net_set_ui.sh

# Run the UI
./net_set_ui.sh
```

#### Option 2: Build Standalone Executable
```bash
# Run the build script
./build_linux.sh

# This creates a standalone executable in build_linux/
# Copy the executable to your desired location and run it
./build_linux/net_set_ui_linux
```

### For Windows Users

#### Option 1: Run Directly (Recommended for development)
```powershell
# Run the UI script
.\net_set_ui.ps1
```

#### Option 2: Build Standalone Executable
```powershell
# Run the build script
.\build_windows.ps1

# This creates files in build_windows/ including:
# - net_set_ui_windows.exe (if ps2exe is available)
# - net_set_ui_windows.bat (batch launcher)
# - launch_net_set_ui.ps1 (PowerShell launcher)
```

## 🎨 Features

### Linux UI (`net_set_ui.sh`)
- **Dual Mode**: Automatically detects GUI environment and uses zenity dialogs, falls back to terminal mode
- **Progress Tracking**: Shows progress bars during configuration and verification
- **User-Friendly Menu**: Easy-to-use interface for all operations
- **Detailed Verification Results**: Scrollable text window showing comprehensive verification output including speed tests and censorship detection
- **Clean Output**: ANSI color codes properly cleaned for GUI display, universal text icons [+] for compatibility
- **Smart Sudo Handling**: Detects root privileges and uses non-interactive sudo when possible
- **Timeout Protection**: 3-minute maximum verification time with graceful completion
- **Enhanced Progress**: Detailed status updates during potentially long operations
- **Status Display**: Shows current network configuration status
- **Error Handling**: Graceful error handling with informative messages

### Windows UI (`net_set_ui.ps1`)
- **Modern GUI**: Clean Windows Forms interface
- **Administrator Detection**: Automatically requests elevation when needed
- **Network Status Viewer**: Detailed network configuration display
- **Comprehensive Verification**: Full verification suite including speed tests, censorship detection, and security checks
- **Enhanced Font Support**: Optimized font selection for Unicode character support (✓, ⚠, ✗)
- **Timeout Protection**: 15-second speed test timeout, 5-second censorship test timeouts
- **Progress Indication**: Visual feedback during operations with detailed progress updates
- **Professional Look**: Consistent with Windows UI standards

## 📋 UI Functionality

Both Linux and Windows versions provide:

1. **Configure Network Settings**
   - Enables IPv6 with security preferences
   - Configures DNS over HTTPS/TLS
   - Applies network security policies
   - Sets up firewall rules (where applicable)

2. **Verify Network Configuration**
   - Tests network connectivity (IPv4/IPv6)
   - Validates DNS configuration and DNS over HTTPS
   - Checks security settings and firewall status
   - Runs performance tests with speed measurements
   - Performs censorship detection tests
   - Displays comprehensive verification results in a dedicated window

3. **View Current Status**
   - Shows active network adapters
   - Displays IP configuration
   - Shows DNS settings
   - Indicates security status

## 🔧 Requirements

### Linux Requirements
- Linux with systemd (for network configuration)
- `sudo` or root access for system changes
- `zenity` (for GUI mode, optional - will fallback to terminal)
- Standard Unix tools: `ip`, `nslookup`, `curl`, `ping`

### Windows Requirements
- Windows 10/11 (recommended)
- PowerShell 5.1 or later
- Administrator privileges for network configuration
- .NET Framework 4.0 or later (for executable version)

## 📦 Building Executables

### Linux Build Process
The Linux build script (`build_linux.sh`) creates:
- **Standalone executable** using `shc` (if available)
- **Self-extracting archive** as fallback
- **Simple launcher script** for script-based deployment

### Windows Build Process
The Windows build script (`build_windows.ps1`) creates:
- **Standalone executable** using `ps2exe` (if available)
- **Batch file launcher** for universal compatibility
- **PowerShell launcher** for PowerShell-based deployment

## 🎯 Usage Examples

### Linux GUI Mode
```bash
# If zenity is installed and X11 is available
./net_set_ui.sh
# Opens graphical dialogs for all operations
```

### Linux Terminal Mode
```bash
# If no GUI environment or zenity not available
./net_set_ui.sh
# Runs in terminal with text-based menus
```

### Windows GUI
```powershell
# Double-click or run from PowerShell
.\net_set_ui.ps1
# Opens Windows Forms interface
```

## 🔒 Security Considerations

- **Administrator Privileges**: Both versions require elevated privileges for network configuration
- **Backup Creation**: The Windows version automatically creates backups before making changes
- **Verification**: Both versions include verification steps to ensure configuration success
- **Rollback**: Backup files allow for manual rollback if needed

## 🐛 Troubleshooting

### Linux Issues
- **GUI not showing**: Install zenity: `sudo apt-get install zenity` (Ubuntu/Debian)
- **Permission denied**: Ensure script is executable and run with appropriate privileges
- **Network configuration fails**: Check systemd-resolved status and DNS settings

### Windows Issues
- **Execution Policy**: Set PowerShell execution policy: `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser`
- **Administrator access**: Right-click and "Run as Administrator" if elevation fails
- **Executable not working**: Use the batch file launcher as fallback

## 📚 Integration with Existing Scripts

The UI wrappers are designed to work seamlessly with the existing network configuration scripts:

- **Linux**: Calls `net_set.sh` and `network-verify.sh`
- **Windows**: Calls `net_set.ps1`
- **Preserves all functionality** of the original scripts
- **Adds user-friendly interface** on top of existing functionality
- **Maintains compatibility** with existing backup and logging systems

## 🔄 Future Enhancements

Potential improvements for future versions:
- **Cross-platform UI**: Single UI that works on both platforms
- **Advanced Configuration**: More granular control over settings
- **Scheduled Tasks**: Ability to schedule regular verification
- **Remote Management**: Web-based interface for remote administration
- **Integration**: Integration with system monitoring tools
