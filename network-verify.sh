#*****************************************************************************#
#                                                                             #
#  network-verify.sh                                      TTTTTTTT SSSSSSS II #
#                                                            TT    SS      II #
#  By: st93642@students.tsi.lv                               TT    SSSSSSS II #
#                                                            TT         SS II #
#  Created: Oct 18 2025 11:20 st93642                        TT    SSSSSSS II #
#  Updated: Oct 18 2025 12:09 st93642                                         #
#                                                                             #
#   Transport and Telecommunication Institute - Riga, Latvia                  #
#                       https://tsi.lv                                        #
#*****************************************************************************#

#!/bin/bash
# network-verify.sh - Verify network security settings

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

echo "=== Network Security Verification ==="

# Check IPv6 status
print_status "IPv6 Status:"
ip -6 addr show | grep inet6 | head -5

# Check DNS configuration
print_status "DNS Configuration:"
cat /etc/resolv.conf

# Check DoH (if using systemd-resolved)
print_status "DNS over HTTPS Status:"
if command -v resolvectl >/dev/null 2>&1; then
    resolvectl status | grep -A5 "Global" || print_warning "Unable to retrieve DoH status"
elif command -v systemd-resolve >/dev/null 2>&1; then
    systemd-resolve --status | grep -A5 "Global" || print_warning "Unable to retrieve DoH status"
else
    print_warning "systemd-resolved/resolvectl not available"
fi

# Check security settings
print_status "Security Settings:"
sysctl net.ipv4.ip_forward net.ipv6.conf.all.disable_ipv6 net.ipv4.conf.all.accept_redirects

# Check firewall status
print_status "Firewall Status:"
iptables -L -n | head -20
echo "..."
ip6tables -L -n | head -20

# Test connectivity
print_status "Connectivity Tests:"
echo -n "IPv4: "
if ping -c1 -W2 8.8.8.8 >/dev/null 2>&1; then
    print_success "OK"
else
    print_error "FAIL"
fi
echo -n "IPv6: "
if ping6 -c1 -W2 ipv6.google.com >/dev/null 2>&1; then
    print_success "OK"
else
    print_warning "FAIL/NONE"
fi
echo -n "DNS: "
if nslookup google.com >/dev/null 2>&1; then
    print_success "OK"
else
    print_error "FAIL"
fi

# Comprehensive DoH test
print_status "DoH Connectivity Tests:"
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
            print_success "DoH: OK (IPv4 and IPv6)"
        elif $doh_ipv4_ok; then
            print_success "DoH: OK (IPv4 only)"
        elif $doh_ipv6_ok; then
            print_success "DoH: OK (IPv6 only)"
        else
            print_warning "DoH: Failed for both IPv4 and IPv6"
        fi
    else
        print_warning "curl not available, skipping DoH test"
    fi
else
    print_warning "No internet connectivity detected, skipping DoH test"
fi

# Test connection to potentially censored website
print_status "Censorship Test (rutube.ru):"
if nslookup rutube.ru >/dev/null 2>&1; then
    echo -n "DNS Resolution: "
    print_success "OK"
    echo -n "HTTPS Status: "
    http_status=$(curl --max-time 15 -s -o /dev/null -w "%{http_code}" https://rutube.ru)
    if [ "$http_status" = "200" ]; then
        print_success "$http_status"
        echo -n "Content Check: "
        if curl --max-time 15 -s https://rutube.ru | grep -q -E "(Подписки|Главная|Видео|Каналы)"; then
            print_success "Russian content detected"
        else
            print_warning "No expected Russian text found"
            echo "Note: Page may be blocked, redirected, or content has changed"
        fi
    else
        print_warning "HTTPS $http_status (possibly blocked)"
    fi
else
    echo -n "DNS Resolution: "
    print_error "FAIL (possibly censored)"
fi