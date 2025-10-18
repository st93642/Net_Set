# Network Security Configuration Scripts

## Overview

This repository contains two Bash scripts for configuring and verifying network security settings on Linux systems:

- `net_set.sh`: Comprehensive network security configuration script
- `network-verify.sh`: Network security verification and testing script

## Features

### net_set.sh

- **IPv6 Configuration**: Enables IPv6 with secure settings
- **DNS over HTTPS (DoH)**: Configures Quad9 DNS with Cloudflare fallback
- **Network Security**: Applies strict sysctl security settings
- **Firewall**: Configures iptables/ip6tables with secure rules
- **Backup**: Creates backups of current configuration before changes

### network-verify.sh

- **IPv6 Status Check**: Displays IPv6 configuration and connectivity
- **DNS Configuration**: Shows current DNS settings
- **DoH Status**: Checks DNS over HTTPS resolver status
- **Security Settings**: Verifies applied sysctl security parameters
- **Firewall Status**: Displays current firewall rules
- **Connectivity Tests**: Tests IPv4/IPv6 and DNS resolution
- **DoH Connectivity**: Tests DoH endpoint accessibility over IPv4/IPv6
- **Censorship Detection**: Tests access to potentially blocked websites

## Requirements

- Linux distribution with systemd
- Root privileges (sudo)
- curl (for DoH and censorship tests)
- iptables/ip6tables
- systemd-resolved

## Installation

1. Clone or download the scripts to your system
2. Make them executable:

   ```bash
   chmod +x net_set.sh network-verify.sh
   ```

## Usage

### Network Security Setup

Run the setup script as root to configure network security:

```bash
sudo ./net_set.sh
```

The script will:

1. Prompt for confirmation
2. Create backups of current settings
3. Enable IPv6 with security settings
4. Configure DNS over HTTPS with Quad9
5. Apply strict network security parameters
6. Configure firewall rules
7. Run verification tests

### Network Verification

Run the verification script to check current network status:

```bash
sudo ./network-verify.sh
```

This script can be run anytime to verify the security configuration and network connectivity.

## Detailed Configuration

### DNS over HTTPS

- Primary: Quad9 (9.9.9.9, 149.112.112.112, IPv6 equivalents)
- Fallback: Cloudflare (1.1.1.1, 1.0.0.1, IPv6 equivalents)
- Features: DNSSEC, caching, malware blocking

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

## Testing and Verification

The scripts include comprehensive testing:

### Connectivity Tests

- IPv4 ping to 8.8.8.8
- IPv6 ping to ipv6.google.com
- DNS resolution of google.com

### DoH Tests

- IPv4 DoH connectivity to Cloudflare
- IPv6 DoH connectivity to Cloudflare
- JSON response validation

### Censorship Tests

- DNS resolution of rutube.ru
- HTTPS connectivity check
- Content validation for Russian text

## Troubleshooting

### Common Issues

1. **"systemd-resolved not available"**
   - Install systemd-resolved: `sudo apt install systemd-resolved` (Ubuntu/Debian)
   - Or `sudo yum install systemd` (RHEL/CentOS)

2. **DoH test fails**
   - Check internet connectivity
   - Verify curl is installed
   - May be blocked by firewall or network policies

3. **Firewall blocks legitimate traffic**
   - Review rules: `sudo iptables -L`
   - Add necessary rules for your services

4. **IPv6 issues**
   - Check if IPv6 is enabled: `ip -6 addr show`
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

## Compatibility

- **Tested on**: Ubuntu, Debian, CentOS, RHEL
- **Requires**: systemd-based systems
- **Network**: Works with IPv4/IPv6 dual-stack

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Contributing

Feel free to submit issues or pull requests for improvements.

## Changelog

- **v1.0**: Initial release with IPv6, DoH, firewall, and verification
- **Updates**: POSIX compatibility, HTTPS-only firewall, comprehensive testing
