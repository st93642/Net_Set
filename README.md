# Network Security Configuration Scripts

## Overview

This repository contains Bash and PowerShell scripts for configuring and verifying network security settings on Linux and Windows systems:

- `net_set.sh`: Linux network security configuration script
- `network-verify.sh`: Linux network security verification script
- `net_set.ps1`: Windows network security configuration script (PowerShell for Windows 10/11)

## Features

### net_set.sh (Linux)

- **IPv6 Configuration**: Enables IPv6 with secure settings
- **DNS over HTTPS (DoH)**: Configures Quad9 DNS with Cloudflare fallback
- **Network Security**: Applies strict sysctl security settings
- **Firewall**: Configures iptables/ip6tables with secure rules
- **Backup**: Creates backups of current configuration before changes

### network-verify.sh (Linux)

- **IPv6 Status Check**: Displays IPv6 configuration and connectivity
- **DNS Configuration**: Shows current DNS settings
- **DoH Status**: Checks DNS over HTTPS resolver status
- **Security Settings**: Verifies applied sysctl security parameters
- **Firewall Status**: Displays current firewall rules
- **Connectivity Tests**: Tests IPv4/IPv6 and DNS resolution
- **DoH Connectivity**: Tests DoH endpoint accessibility over IPv4/IPv6
- **Censorship Detection**: Tests access to potentially blocked websites

## Requirements

### Linux

- Linux distribution with systemd
- Root privileges (sudo)
- curl (for DoH and censorship tests)
- iptables/ip6tables
- systemd-resolved

### Windows

- Windows 10 version 2004 or later / Windows 11
- Administrator privileges
- PowerShell 5.1 or later (or PowerShell Core)
- Internet connection

## Installation

1. Clone or download the scripts to your system
2. For Linux: Make them executable:

   ```bash
   chmod +x net_set.sh network-verify.sh
   ```

## Usage

### Network Security Setup (Linux)

Run the setup script as root to configure network security:

```bash
sudo ./net_set.sh
```

The script will:

1. Prompt for confirmation
2. Create backups of current settings
3. Enable IPv6 with security settings
4. Configure DNS over HTTPS with Quad9 (default)
5. Apply strict network security parameters
6. Configure firewall rules
7. Run verification tests

### Network Verification (Linux)

Run the verification script to check current network status:

```bash
sudo ./network-verify.sh
```

This script can be run anytime to verify the security configuration and network connectivity.

### Windows - `net_set.ps1`

The PowerShell script `net_set.ps1` performs equivalent actions on Windows 10/11. Key features:

- Backups of network configuration and firewall policy are saved to `C:\Windows\Temp\net_set_backup_<timestamp>`
- Enables IPv6 and per-adapter IPv6 binding
- Configures DNS over HTTPS (DoH) via Windows policy registry (supports Cloudflare, Quad9, OpenDNS, NextDNS)
- Applies best-effort network hardening registry changes (disable IP forwarding, ICMP redirects, etc.)
- Configures Windows Defender Firewall rules (allow SSH 22, HTTPS 443; block HTTP 80 by default)
- Verification: shows local IPv4/IPv6 addresses, public IP (via ident.me), DNS resolution, DoH test (curl), connectivity pings

Run the Windows script in an elevated PowerShell prompt:

```powershell
# Interactive run
powershell -ExecutionPolicy Bypass -File .\net_set.ps1
```

Non-interactive options (environment variables):

- `PREFERRED_DOH_PROVIDER` — set to one of `Cloudflare`, `Quad9`, `OpenDNS`, `NextDNS` to pre-select DoH provider
- `NEXTDNS_ID` — when `PREFERRED_DOH_PROVIDER=NextDNS`, set this to your NextDNS configuration ID to use the per-config endpoint

Example (PowerShell):

```powershell
$env:PREFERRED_DOH_PROVIDER = 'Cloudflare'
$env:NEXTDNS_ID = 'your-nextdns-id-if-applicable'
powershell -ExecutionPolicy Bypass -File .\net_set.ps1
```

Notes:

- DoH policy changes may require a reboot or Group Policy refresh to take effect. If the machine is domain-joined, local policy edits may be overridden by AD group policies.
- The script attempts to use `curl` for DoH tests if available; otherwise it uses PowerShell web requests.
- The script pauses at the end with "Press Enter to close..." so the console window remains open for review.

## Detailed Configuration

### DNS over HTTPS

- Supported providers (Windows script): Cloudflare, Quad9, OpenDNS, NextDNS

- Default Linux setup uses Quad9 with Cloudflare fallback

## Provider templates used by `net_set.ps1`

- Cloudflare: `https://cloudflare-dns.com/dns-query` (IPs: `1.1.1.1`, `2606:4700:4700::1111`)
- Quad9: `https://dns.quad9.net/dns-query` (IPs: `9.9.9.9`, `149.112.112.112`, `2620:fe::fe`, `2620:fe::9`)
- OpenDNS: `https://doh.opendns.com/dns-query` (IPs: `208.67.222.222`, `208.67.220.220`)
- NextDNS: `https://dns.nextdns.io/<config-id>` (requires user config ID for per-profile endpoint)

### Firewall Rules

- **Default Policy**: INPUT DROP, OUTPUT ACCEPT, FORWARD DROP
- **Allowed Incoming**:
  - SSH (port 22)
  - HTTPS (port 443)
  - ICMP (ping)
  - Established connections
- **IPv6 Support**: Identical rules for IPv6

### Security Settings

- **IPv4**: Disabled IP forwarding, redirects, source routing
- **IPv6**: Disabled redirects, router advertisements, forwarding
- **TCP**: SYN cookies, optimized buffer sizes
- **ICMP**: Broadcast ignore, bogus response filtering

## Troubleshooting

### Common Issues

1. **"systemd-resolved not available"**
   - Install systemd-resolved: `sudo apt install systemd-resolved` (Ubuntu/Debian)
   - Or `sudo yum install systemd` (RHEL/CentOS)

2. **DoH test fails**
   - Check internet connectivity
   - Verify curl is installed (Linux) or PowerShell has internet access (Windows)
   - May be blocked by firewall, proxy, or network policies
   - On Windows: Check if TLS 1.2+ is enabled and PowerShell execution policy allows web requests

3. **Firewall blocks legitimate traffic**
   - Review rules: `sudo iptables -L` (Linux) or `Get-NetFirewallRule` (Windows)
   - Add necessary rules for your services

4. **IPv6 issues**
   - Check if IPv6 is enabled: `ip -6 addr show` (Linux) or `Get-NetAdapter | Get-NetIPAddress` (Windows)
   - Verify ISP supports IPv6

### Recovery

- Backups are created in `/etc/network/backup_YYYYMMDD_HHMMSS/`
- Restore files manually if needed
- Reboot may be required for some changes

## Security Considerations

- **Firewall**: Blocks all incoming traffic except essential services
- **DNS**: Uses encrypted DNS with malware blocking
- **IPv6**: Configured with security best practices
- **Sysctl**: Hardened network stack parameters

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Contributing

Feel free to submit issues or pull requests for improvements.

## Changelog

- **v1.0**: Initial release with IPv6, DoH, firewall, and verification
- **Updates**: POSIX compatibility, HTTPS-only firewall, comprehensive testing
