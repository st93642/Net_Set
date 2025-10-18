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

printf "${BLUE}=== Network Security Verification ===${NC}\n"

# Check IPv6 status
print_status "IPv6 Status:"
ip -6 addr show | grep inet6 | head -5

# Check DNS configuration
print_status "DNS Configuration:"
grep -E "^nameserver|^options|^search" /etc/resolv.conf || print_warning "Unable to read resolv.conf"

# Check DoH (if using systemd-resolved)
print_status "DNS over HTTPS Status:"
if command -v resolvectl >/dev/null 2>&1; then
    resolvectl status | grep -A5 "Global" || print_warning "Unable to retrieve DoH status"
elif command -v systemd-resolve >/dev/null 2>&1; then
    systemd-resolve --status | grep -A5 "Global" || print_warning "Unable to retrieve DoH status"
else
    print_warning "systemd-resolved/resolvectl not available"
fi

section() {
    printf "\n${BLUE}=== %s ===${NC}\n" "$1"
}

subsection() {
    printf "${YELLOW}--- %s ---${NC}\n" "$1"
}

get_pubip() {
    ipver=$1
    if command -v curl >/dev/null 2>&1; then
        if [ "$ipver" = "v4" ]; then
            curl -s --ipv4 https://v4.ident.me || echo "N/A"
        else
            curl -s --ipv6 https://v6.ident.me || echo "N/A"
        fi
    elif command -v wget >/dev/null 2>&1; then
        if [ "$ipver" = "v4" ]; then
            wget -qO- --inet4-only https://v4.ident.me || echo "N/A"
        else
            wget -qO- --inet6-only https://v6.ident.me || echo "N/A"
        fi
    else
        echo "N/A"
    fi
}

section "Public IPs (ident.me)"
subsection "Public IPv4"
printf "    %s\n" "$(get_pubip v4)"
subsection "Public IPv6"
printf "    %s\n" "$(get_pubip v6)"

section "Local Interface Addresses"
# Show IPv4 and IPv6 per interface, skip link-local for IPv6
ip -o link show | awk -F': ' '{print $2}' | while read -r ifline; do
    iface=$(echo "$ifline" | awk '{$1=$1;print}')
    if [ -z "$iface" ]; then continue; fi
    subsection "Interface: $iface"
    ip -4 addr show dev "$iface" | awk '/inet /{print "    IPv4: " $2}' || echo "    IPv4: none"
    ip -6 addr show dev "$iface" | awk '/inet6 /{ if ($2 !~ /^fe80:/) print "    IPv6: " $2 }' || echo "    IPv6: none"
done

section "Current Network Settings"
subsection "Active Interfaces Summary"
ip -o addr show | awk '$3 == "inet" || $3 == "inet6" { if ($4 !~ /^fe80:/) print "    " $2 ": " $4 }' | sort -u
subsection "Routing Table (default routes)"
ip route show | grep "^default" | sed 's/^/    /'
subsection "DNS Servers"
grep "^nameserver" /etc/resolv.conf | sed 's/^/    /'

print_success "Summary complete"


# Check security settings
print_status "Security Settings:"
sysctl net.ipv4.ip_forward net.ipv6.conf.all.disable_ipv6 net.ipv4.conf.all.accept_redirects

# Check firewall status
# print_status "Firewall Status:"
# iptables -L -n | head -20
# echo "..."
# ip6tables -L -n | head -20

# Test connectivity
print_status "Connectivity Tests:"
printf "${GREEN}IPv4:${NC} "
if ping -c1 -W2 8.8.8.8 >/dev/null 2>&1; then
    print_success "OK"
else
    print_error "FAIL"
fi
printf "${GREEN}IPv6:${NC} "
if ping6 -c1 -W2 ipv6.google.com >/dev/null 2>&1; then
    print_success "OK"
else
    print_warning "FAIL/NONE"
fi
printf "${GREEN}DNS:${NC} "
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
    printf "${GREEN}DNS Resolution:${NC} "
    print_success "OK"
    printf "${GREEN}HTTPS Status:${NC} "
    http_status=$(curl --max-time 15 -s -o /dev/null -w "%{http_code}" https://rutube.ru)
    if [ "$http_status" = "200" ]; then
        print_success "$http_status"
        printf "${GREEN}Content Check:${NC} "
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
    printf "${GREEN}DNS Resolution:${NC} "
    print_error "FAIL (possibly censored)"
fi