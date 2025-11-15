# Installation and Usage Guide

## 🚀 Quick Installation

### Linux Users

1. **Download the Scripts**

   ```bash
   git clone <repository-url>
   cd Net_Set
   ```

2. **Make Scripts Executable**

   ```bash
   chmod +x net_set_ui.sh build_linux.sh
   ```

3. **Run the UI**

   ```bash
   ./net_set_ui.sh
   ```

4. **Build Standalone Executable (Optional)**

   ```bash
   ./build_linux.sh
   # This creates build_linux/net_set_ui_linux
   ```

### Windows Users

1. **Download the Scripts**
   - Extract all files to a folder

2. **Run the UI**

   ```powershell
   # Right-click on net_set_ui.ps1 and "Run with PowerShell"
   # Or run from PowerShell:
   .\net_set_ui.ps1
   ```

3. **Build Standalone Executable (Optional)**

   ```powershell
   .\build_windows.ps1
   # This creates build_windows/net_set_ui_windows.exe
   ```

## 📋 What the UI Does

### Main Features

1. **Configure Network Settings** - Apply IPv6, DNS over HTTPS, security policies
2. **Verify Network Configuration** - Test connectivity and security settings
3. **View Current Status** - Display current network configuration

### Linux UI Features

- **Automatic GUI Detection**: Uses zenity if available, falls back to terminal
- **Progress Bars**: Visual feedback during configuration
- **Color-coded Output**: Easy to read status messages
- **Error Handling**: Graceful error handling with informative messages

### Windows UI Features

- **Modern Windows Forms Interface**: Professional look and feel
- **Automatic Elevation**: Requests Administrator privileges when needed
- **Detailed Status Display**: Comprehensive network information viewer
- **Progress Indication**: Visual feedback during operations

## 🔧 Requirements

### Linux

- Ubuntu/Debian/RHEL/CentOS/Arch Linux
- systemd (for network configuration)
- sudo access
- zenity (optional, for GUI mode)

### Windows

- Windows 10/11
- PowerShell 5.1+
- Administrator privileges

## 📦 File Structure

```
Net_Set/
├── net_set_ui.sh              # Linux UI wrapper
├── net_set_ui.ps1             # Windows UI wrapper
├── net_set.sh                 # Linux configuration script
├── net_set.ps1                # Windows configuration script
├── network-verify.sh          # Linux verification script
├── build_linux.sh             # Linux build script
├── build_windows.ps1          # Windows build script
├── UI_README.md               # Detailed UI documentation
└── README.md                  # Main project documentation
```

## 🎯 Usage Examples

### Linux GUI Mode

```bash
./net_set_ui.sh
# Opens graphical interface (if zenity is available)
```

### Linux Terminal Mode

```bash
./net_set_ui.sh
# Falls back to terminal mode (no GUI)
```

### Windows GUI

```powershell
.\net_set_ui.ps1
# Opens Windows Forms interface
```

## 🔒 Security Notes

- **Administrator privileges required** for network configuration
- **Backups are created** before making changes (Windows version)
- **Verification steps** ensure configuration success
- **Rollback possible** using backup files

## 🐛 Troubleshooting

### Linux

- **GUI not showing**: Install zenity: `sudo apt install zenity`
- **Permission denied**: Use `sudo ./net_set_ui.sh`
- **Script not found**: Ensure all files are in the same directory

### Windows

- **Execution policy**: `Set-ExecutionPolicy RemoteSigned -Scope CurrentUser`
- **Administrator access**: Right-click and "Run as Administrator"
- **PowerShell blocked**: Run `powershell.exe -ExecutionPolicy Bypass`

## 📚 Advanced Usage

### Building Standalone Executables

#### Linux

```bash
./build_linux.sh
# Creates build_linux/net_set_ui_linux
```

#### Windows

```powershell
.\build_windows.ps1
# Creates build_windows/net_set_ui_windows.exe
```

### Custom Configuration

The UI wrappers can be customized by editing:

- `net_set_ui.sh` (Linux)
- `net_set_ui.ps1` (Windows)

Both scripts call the original configuration scripts, so all functionality is preserved.

## 🔄 Integration

The UI wrappers are designed to:

- **Preserve all existing functionality** of the original scripts
- **Add user-friendly interface** on top of existing tools
- **Maintain compatibility** with existing backup and logging systems
- **Support both GUI and terminal modes** (Linux)

## 📞 Support

For issues with:

- **Network configuration**: Check the original script documentation
- **UI interface**: Check UI_README.md for detailed information
- **Build process**: Review the build scripts for error messages
