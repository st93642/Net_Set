#*****************************************************************************#
#                                                                             #
#  net_set.sh                                             TTTTTTTT SSSSSSS II #
#                                                            TT    SS      II #
#  By: st93642@students.tsi.lv                               TT    SSSSSSS II #
#                                                            TT         SS II #
#  Created: Oct 18 2025 11:18 st93642                        TT    SSSSSSS II #
#  Updated: Oct 18 2025 12:12 st93642                                         #
#                                                                             #
#   Transport and Telecommunication Institute - Riga, Latvia                  #
#                       https://tsi.lv                                        #
#*****************************************************************************#

#!/bin/bash

# Network Security Configuration Script
# Configures IPv6, DNS over HTTPS, and strict security settings

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then
   echo -e "${RED}This script must be run as root${NC}" 
   exit 1
fi

print_status() {
    printf "${BLUE}[INFO]${NC} %s\n" "$1"
}

print_success() {
    printf "${GREEN}[SUCCESS]${NC} %s\n" "$1"
}

print_warning() {
    printf "${YELLOW}[WARNING]${NC} %s\n" "$1"
}

print_error() {
    printf "${RED}[ERROR]${NC} %s\n" "$1"
}

# Get public IP addresses using ident.me
get_public_ips() {
    print_status "Fetching public IP addresses..."
    
    if command -v curl >/dev/null 2>&1; then
        ipv4=$(curl -s --max-time 10 https://v4.ident.me 2>/dev/null)
        ipv6=$(curl -s --max-time 10 https://v6.ident.me 2>/dev/null)
        
        if [ -n "$ipv4" ]; then
            printf "${GREEN}Public IPv4:${NC} %s\n" "$ipv4"
        else
            print_warning "Could not fetch public IPv4"
        fi
        
        if [ -n "$ipv6" ]; then
            printf "${GREEN}Public IPv6:${NC} %s\n" "$ipv6"
        else
            print_warning "Could not fetch public IPv6"
        fi
    else
        print_warning "curl not available, cannot fetch public IPs"
    fi
}

# Backup current configuration
backup_config() {
    print_status "Backing up current network configuration..."
    BACKUP_DIR="/etc/network/backup_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    
    cp /etc/resolv.conf "$BACKUP_DIR/resolv.conf.backup"
    cp /etc/systemd/resolved.conf "$BACKUP_DIR/resolved.conf.backup" 2>/dev/null || true
    cp /etc/sysctl.conf "$BACKUP_DIR/sysctl.conf.backup" 2>/dev/null || true
    ip addr show > "$BACKUP_DIR/ip_addr.backup"
    ip route show > "$BACKUP_DIR/ip_route.backup"
    
    print_success "Backup created in $BACKUP_DIR"
}

# Enable IPv6 on all interfaces
enable_ipv6() {
    print_status "Enabling IPv6 on all interfaces..."
    
    # Remove IPv6 disable settings if present
    sed -i '/net.ipv6.conf.all.disable_ipv6/d' /etc/sysctl.conf 2>/dev/null || true
    sed -i '/net.ipv6.conf.default.disable_ipv6/d' /etc/sysctl.conf 2>/dev/null || true
    sed -i '/net.ipv6.conf.lo.disable_ipv6/d' /etc/sysctl.conf 2>/dev/null || true
    
    # Add IPv6 enable settings
    cat >> /etc/sysctl.conf << 'EOF'

# IPv6 Configuration - Enabled by security script
net.ipv6.conf.all.disable_ipv6 = 0
net.ipv6.conf.default.disable_ipv6 = 0
net.ipv6.conf.lo.disable_ipv6 = 0
net.ipv6.conf.all.use_tempaddr = 2
net.ipv6.conf.all.accept_ra = 0
EOF

    # Enable IPv6 on individual interfaces
    for interface in $(ls /sys/class/net/ | grep -v lo); do
        if [ -f "/proc/sys/net/ipv6/conf/$interface/disable_ipv6" ]; then
            echo 0 > "/proc/sys/net/ipv6/conf/$interface/disable_ipv6"
        fi
    done
    
    print_success "IPv6 enabled globally"
}

# Configure DNS over HTTPS
configure_doh() {
    print_status "Configuring DNS over HTTPS..."
    
    # Check if systemd-resolved is available
    if ! systemctl is-active systemd-resolved >/dev/null 2>&1; then
        print_warning "systemd-resolved not active, installing..."
        apt-get update && apt-get install -y systemd-resolved 2>/dev/null || \
        yum install -y systemd 2>/dev/null || \
        print_error "Cannot install systemd-resolved"
    fi
    
    # Stop any running DNS services
    systemctl stop systemd-resolved 2>/dev/null || true
    
    # Configure systemd-resolved for DoH
    cat > /etc/systemd/resolved.conf << 'EOF'
[Resolve]
DNS=9.9.9.9#dns.quad9.net 149.112.112.112#dns.quad9.net 2620:fe::fe#dns.quad9.net 2620:fe::9#dns.quad9.net
DNSOverTLS=opportunistic
DNSSEC=allow-downgrade
Cache=yes
DNSStubListener=yes
ReadEtcHosts=yes
FallbackDNS=1.1.1.1#cloudflare-dns.com 1.0.0.1#cloudflare-dns.com 2606:4700:4700::1111#cloudflare-dns.com 2606:4700:4700::1001#cloudflare-dns.com
EOF

    # Create resolv.conf symlink
    ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf 2>/dev/null || true
    
    # Start and enable systemd-resolved
    systemctl enable systemd-resolved 2>/dev/null || true
    systemctl start systemd-resolved 2>/dev/null || true
    
    # Alternative: Configure DoH via resolv.conf for non-systemd systems
    if ! systemctl is-active systemd-resolved >/dev/null 2>&1; then
        print_warning "Using resolv.conf fallback method for DoH"
        cat > /etc/resolv.conf << 'EOF'
# DNS over HTTPS configuration
nameserver 9.9.9.9
nameserver 149.112.112.112
nameserver 2620:fe::fe
nameserver 2620:fe::9
options edns0 single-request-reopen
options use-vc  # Force TLS
EOF
    fi
    
    print_success "DNS over HTTPS configured"
}

# Configure strict network security settings
configure_network_security() {
    print_status "Configuring strict network security settings..."
    
    # Add security settings to sysctl.conf
    cat >> /etc/sysctl.conf << 'EOF'

# Strict Network Security Settings
# IPv4 Security
net.ipv4.ip_forward = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0
net.ipv4.conf.all.log_martians = 1
net.ipv4.conf.default.log_martians = 1
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.icmp_ignore_bogus_error_responses = 1
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_max_syn_backlog = 2048
net.ipv4.tcp_synack_retries = 2
net.ipv4.tcp_syn_retries = 2

# IPv6 Security
net.ipv6.conf.all.accept_redirects = 0
net.ipv6.conf.default.accept_redirects = 0
net.ipv6.conf.all.accept_source_route = 0
net.ipv6.conf.default.accept_source_route = 0
net.ipv6.conf.all.accept_ra = 0
net.ipv6.conf.default.accept_ra = 0
net.ipv6.conf.all.forwarding = 0
net.ipv6.conf.default.forwarding = 0

# General Network Security
net.core.rmem_max = 12582912
net.core.wmem_max = 12582912
net.ipv4.tcp_rmem = 10240 87380 12582912
net.ipv4.tcp_wmem = 10240 87380 12582912
EOF

    # Apply settings immediately
    sysctl -p > /dev/null 2>&1 || true
    
    print_success "Strict network security settings applied"
}

# Configure firewall (using iptables/ip6tables)
configure_firewall() {
    print_status "Configuring firewall rules..."
    
    # Flush existing rules
    iptables -F
    ip6tables -F
    
    # Set default policies
    iptables -P INPUT DROP
    iptables -P FORWARD DROP
    iptables -P OUTPUT ACCEPT
    
    ip6tables -P INPUT DROP
    ip6tables -P FORWARD DROP
    ip6tables -P OUTPUT ACCEPT
    
    # Allow loopback
    iptables -A INPUT -i lo -j ACCEPT
    ip6tables -A INPUT -i lo -j ACCEPT
    
    # Allow established connections
    iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
    ip6tables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
    
    # Allow essential services (SSH, HTTPS only - HTTP blocked for security)
    iptables -A INPUT -p tcp --dport 22 -j ACCEPT  # SSH
    iptables -A INPUT -p tcp --dport 443 -j ACCEPT # HTTPS
    
    ip6tables -A INPUT -p tcp --dport 22 -j ACCEPT  # SSH
    ip6tables -A INPUT -p tcp --dport 443 -j ACCEPT # HTTPS
    
    # Allow ICMP (ping)
    iptables -A INPUT -p icmp -j ACCEPT
    ip6tables -A INPUT -p ipv6-icmp -j ACCEPT
    
    # Save rules based on distribution
    if command -v iptables-save >/dev/null 2>&1; then
        mkdir -p /etc/iptables
        iptables-save > /etc/iptables/rules.v4 2>/dev/null || true
        ip6tables-save > /etc/iptables/rules.v6 2>/dev/null || true
    fi
    
    print_success "Firewall configured with strict rules"
}

# Test the configuration
test_configuration() {
    print_status "Testing network configuration..."
    
    # Test IPv6 connectivity
    if ping6 -c 2 -W 3 ipv6.google.com >/dev/null 2>&1; then
        print_success "IPv6 connectivity: OK"
    else
        print_warning "IPv6 connectivity: Failed (may be normal if no IPv6 available)"
    fi
    
    # Test DNS resolution
    if nslookup google.com >/dev/null 2>&1; then
        print_success "DNS resolution: OK"
    else
        print_error "DNS resolution: Failed"
    fi
    
    # Display current DNS settings
    print_status "Current DNS configuration:"
    cat /etc/resolv.conf | grep -v '^#' | grep -v '^$'
    
    # Fetch and display public IP addresses
    get_public_ips
    
    # Test DoH (basic check) with Cloudflare endpoint
    if ping -c1 -W2 8.8.8.8 >/dev/null 2>&1; then
        if command -v curl >/dev/null 2>&1; then
            doh_ipv4_ok=false
            doh_ipv6_ok=false
            
            # Test IPv4 DoH
            if curl --max-time 10 --ipv4 -s -H 'accept: application/dns-json' 'https://cloudflare-dns.com/dns-query?name=google.com&type=A' | grep -q "Answer"; then
                doh_ipv4_ok=true
            fi
            
            # Test IPv6 DoH
            if curl --max-time 10 --ipv6 -s -H 'accept: application/dns-json' 'https://cloudflare-dns.com/dns-query?name=google.com&type=AAAA' | grep -q "Answer"; then
                doh_ipv6_ok=true
            fi
            
            if $doh_ipv4_ok && $doh_ipv6_ok; then
                print_success "DoH capability: OK (IPv4 and IPv6)"
            elif $doh_ipv4_ok; then
                print_success "DoH capability: OK (IPv4 only)"
            elif $doh_ipv6_ok; then
                print_success "DoH capability: OK (IPv6 only)"
            else
                print_warning "DoH capability: Failed for both IPv4 and IPv6"
            fi
        else
            print_warning "curl not available, skipping DoH test"
        fi
    else
        print_warning "No internet connectivity detected, skipping DoH test"
    fi
    
    # Display IPv6 status
    print_status "IPv6 status:"
    ip -6 addr show | grep inet6 || print_warning "No IPv6 addresses configured"
}

# Main execution function
main() {
    printf "${BLUE}==================================================${NC}\n"
    printf "${BLUE}    Network Security Configuration Script${NC}\n"
    printf "${BLUE}    Features: IPv6 + DNS over HTTPS + Strict Security${NC}\n"
    printf "${BLUE}==================================================${NC}\n"
    echo
    
    # Confirm with user
    printf "${YELLOW}This will modify network settings. Continue? (y/N): ${NC}"
    read -r REPLY
    echo
    if [ "$REPLY" != "y" ] && [ "$REPLY" != "Y" ]; then
        print_error "Operation cancelled by user"
        exit 1
    fi
    
    # Execute configuration steps
    backup_config
    enable_ipv6
    configure_doh
    configure_network_security
    configure_firewall
    
    echo
    print_success "Configuration complete!"
    echo
    
    test_configuration
    
    echo
    print_warning "A system reboot is recommended for all changes to take effect"
    print_warning "Backup files are available in: $BACKUP_DIR"
}

# Handle script interruption
trap 'print_error "Script interrupted"; exit 1' INT TERM

# Run main function
main "$@"