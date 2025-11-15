# Net_Set - Network Security Configuration Scripts

A collection of scripts to configure secure network settings with IPv6, DNS over HTTPS (DoH), and strict security policies.

## 🎉 NEW: Desktop UI Wrappers

**User-friendly graphical interfaces are now available!**

- 🖥️ **Linux GUI**: `net_set_ui.sh` - Automatic GUI (zenity) with terminal fallback
- 🪟 **Windows GUI**: `net_set_ui.ps1` - Modern Windows Forms interface  
- 📦 **Standalone executables**: Build scripts for both platforms

**Quick UI Start:**
```bash
# Linux
./net_set_ui.sh

# Windows
.\net_set_ui.ps1
```

See [UI_README.md](UI_README.md) for detailed UI documentation and [INSTALLATION.md](INSTALLATION.md) for installation guide.

## 📋 What These Scripts Do

- **Enable IPv6** on all network interfaces
- **Configure DNS over HTTPS** for encrypted DNS queries
- **Apply strict security settings** to protect against network attacks
- **Set up firewall rules** for enhanced security
- **Test network connectivity** and performance
- **Verify security configurations** are working properly

## 🚀 Quick Start

### 🎯 Recommended: Use the Desktop UI

#### Linux Users
```bash
# Download and run the UI
git clone https://github.com/st93642/Net_Set.git
cd Net_Set
chmod +x net_set_ui.sh
./net_set_ui.sh
```

#### Windows Users
```powershell
# Download and extract files, then run
.\net_set_ui.ps1
```

### 📜 Manual Script Usage

#### For Linux Users

#### Step 1: Download the Scripts

```bash
# If you have git installed:
git clone https://github.com/st93642/Net_Set.git
cd Net_Set

# Or download the files directly to your computer
```

#### Step 2: Make Scripts Executable

```bash
chmod +x net_set.sh network-verify.sh
```

#### Step 3: Run the Configuration Script

```bash
# Run as administrator (required for system changes)
sudo ./net_set.sh
```

#### Step 4: Verify Everything Works

```bash
# Test your network configuration (requires sudo for system access)
sudo ./network-verify.sh
```

#### For Windows Users

#### Step 1: Download the Scripts

- Download all files to a folder on your computer (e.g., `C:\Net_Set\`)

#### Step 2: Run PowerShell as Administrator

1. Press `Windows + X`
2. Select "Windows PowerShell (Admin)" or "Terminal (Admin)"
3. Click "Yes" when prompted by User Account Control

#### Step 3: Navigate to Script Folder

```powershell
cd C:\Net_Set
```

#### Step 4: Run the Configuration Script

```powershell
.\net_set.ps1
```

#### Step 5: Verify Everything Works

The Windows script includes built-in verification that runs automatically after configuration:

- ✅ IPv4/IPv6 connectivity tests
- ✅ DNS resolution tests  
- ✅ DoH (DNS over HTTPS) tests
- ✅ Public IP address detection
- ✅ Local interface information
- ✅ Firewall rule verification

## 📖 Detailed Instructions

### Linux Installation (Ubuntu/Debian)

#### Prerequisites

- Ubuntu 18.04+ or Debian 10+
- Internet connection
- Administrator access (sudo)

#### Step-by-Step Installation

1. **Open Terminal**
   - Press `Ctrl + Alt + T`
   - Or search for "Terminal" in applications

2. **Download Scripts**

   ```bash
   # Download the repository
   git clone https://github.com/st93642/Net_Set.git
   cd Net_Set
   ```

3. **Make Scripts Executable**

   ```bash
   chmod +x *.sh
   ```

4. **Run Configuration Script**

   ```bash
   sudo ./net_set.sh
   ```

   - Enter your password when prompted
   - Type `y` when asked to continue
   - Wait for the script to complete

5. **Test Your Configuration**

```bash
# Run verification with sudo for system access
sudo ./network-verify.sh
```

#### What Happens During Installation

- ✅ Backs up your current network settings
- ✅ Enables IPv6 on all interfaces
- ✅ Configures DNS over HTTPS (encrypted DNS)
- ✅ Applies strict security settings
- ✅ Sets up firewall rules
- ✅ Tests the configuration

### Windows Installation

#### Prerequisites

- Windows 10/11
- PowerShell 5.0+
- Administrator access

#### Step-by-Step Installation

1. **Download Scripts**
   - Download all files to a folder (e.g., `C:\Net_Set\`)

2. **Open PowerShell as Administrator**
   - Press `Windows + X`
   - Select "Windows PowerShell (Admin)"
   - Click "Yes" when prompted

3. **Enable Script Execution**

   ```powershell
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
   ```

4. **Navigate to Script Folder**

   ```powershell
   cd C:\Net_Set
   ```

5. **Run Configuration Script**

   ```powershell
   .\net_set.ps1
   ```

6. **Test Your Configuration**

The Windows script automatically runs comprehensive verification tests after configuration:

- ✅ IPv4/IPv6 connectivity tests
- ✅ DNS resolution tests  
- ✅ DoH (DNS over HTTPS) tests
- ✅ Public IP address detection
- ✅ Local interface information
- ✅ Firewall rule verification

## 🔧 Troubleshooting

### Common Issues

#### "Permission Denied" Error (Linux)

```bash
# Solution: Run with sudo
sudo ./net_set.sh
sudo ./network-verify.sh
```

#### "Execution Policy" Error (Windows)

```powershell
# Solution: Enable script execution
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

#### "Command Not Found" Error

```bash
# Solution: Make sure you're in the right directory
pwd
ls -la *.sh
```

#### Network Issues After Configuration

```bash
# Solution: Restart network services
sudo systemctl restart systemd-resolved
sudo systemctl restart NetworkManager
```

### Restoring Original Settings

#### Linux

```bash
# The script creates backups in /etc/network/backup_*
# To restore:
sudo cp /etc/network/backup_*/resolv.conf.backup /etc/resolv.conf
sudo cp /etc/network/backup_*/resolved.conf.backup /etc/systemd/resolved.conf
sudo systemctl restart systemd-resolved
```

#### Windows

```powershell
# Restore network settings
netsh winsock reset
netsh int ip reset
# Restart your computer
```

## 📊 Understanding the Output

### Network Verification Results

When you run `network-verify.sh`, you'll see:

- **IPv6 Status**: Shows if IPv6 is working
- **DNS Configuration**: Your DNS servers
- **Public IPs**: Your external IP addresses
- **Security Settings**: Kernel security parameters
- **Connectivity Tests**: Ping tests to various servers
- **Speed Test**: Download/upload speeds

### What the Colors Mean

- 🟢 **Green**: Everything working correctly
- 🟡 **Yellow**: Warning or information
- 🔴 **Red**: Error or failure
- 🔵 **Blue**: Status information

## 🛡️ Security Features

### What Gets Configured

1. **IPv6 Security**
   - Enables IPv6 on all interfaces
   - Disables IPv6 forwarding
   - Blocks IPv6 redirects

2. **DNS Security**
   - DNS over HTTPS (DoH) encryption
   - DNSSEC validation
   - Secure DNS servers (Quad9, Cloudflare)

3. **Network Security**
   - Disables IP forwarding
   - Blocks ICMP redirects
   - Enables SYN cookies
   - Strict firewall rules

4. **Firewall Rules**
   - Blocks all incoming connections by default
   - Allows only SSH (port 22) and HTTPS (port 443)
   - Allows established connections
   - Blocks all other traffic

## 📞 Support

### Getting Help

1. **Check the verification script output** for error messages
2. **Look at the backup files** in `/etc/network/backup_*` (Linux)
3. **Restart your computer** if you experience issues
4. **Restore from backup** if needed (see troubleshooting section)

### Common Questions

**Q: Will this break my internet connection?**
A: No, the scripts are designed to maintain connectivity while adding security.

**Q: Can I undo the changes?**
A: Yes, the script creates backups and provides restore instructions.

**Q: Do I need to restart my computer?**
A: A restart is recommended for all changes to take effect.

**Q: Will this slow down my internet?**
A: No, it may actually improve performance with better DNS settings.

## 📝 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🤝 Contributing

Feel free to submit issues and enhancement requests!

---

**Note**: These scripts modify system network settings. Always backup your system before running them, and test in a safe environment first.
