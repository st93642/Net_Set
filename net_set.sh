#!/bin/bash

#*****************************************************************************#
#                                                                             #
#  net_set_simple.sh                                      TTTTTTTT SSSSSSS II #
#                                                            TT    SS      II #
#  By: st93642@students.tsi.lv                               TT    SSSSSSS II #
#                                                            TT         SS II #
#  Created: Oct 18 2025 11:18 st93642                        TT    SSSSSSS II #
#  Updated: Oct 29 2025 19:31 st93642                                         #
#                                                                             #
#   Transport and Telecommunication Institute - Riga, Latvia                  #
#                       https://tsi.lv                                        #
#*****************************************************************************#

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}=== Network Configuration Script ===${NC}"
echo
echo "This script will configure:"
echo "  1. IPv6 preference"
echo "  2. DHCP DNS isolation"
echo "  3. DNS over TLS (Cloudflare)"
echo "  4. Run connectivity and censorship tests"
echo
read -p "Apply these changes? (y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 0
fi

if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Error: This script must be run as root${NC}"
    exit 1
fi

echo -e "\n${GREEN}[1/7] Configuring IPv6 sysctl...${NC}"
cat > /etc/sysctl.d/90-net-set-ipv6.conf <<'EOF'
net.ipv6.conf.all.disable_ipv6 = 0
net.ipv6.conf.default.disable_ipv6 = 0
net.ipv6.conf.lo.disable_ipv6 = 0
net.ipv6.conf.all.use_tempaddr = 2
EOF
sysctl --system >/dev/null 2>&1

echo -e "${GREEN}[2/7] Setting IPv6 preference...${NC}"
if ! grep -q "net_set.sh IPv6 preference" /etc/gai.conf 2>/dev/null; then
    cat >> /etc/gai.conf <<'EOF'
# net_set.sh IPv6 preference
precedence ::ffff:0:0/96  10
EOF
fi

echo -e "${GREEN}[3/7] Configuring DHCP DNS isolation...${NC}"
mkdir -p /etc/dhcp/dhclient-enter-hooks.d
cat > /etc/dhcp/dhclient-enter-hooks.d/99-net-set-ignore-dns <<'EOF'
#!/bin/bash
make_resolv_conf() { :; }
EOF
chmod +x /etc/dhcp/dhclient-enter-hooks.d/99-net-set-ignore-dns

echo -e "${GREEN}[4/7] Testing DoH providers...${NC}"
DOH_PROVIDER="cloudflare"
if command -v curl >/dev/null 2>&1; then
    if curl --max-time 5 -s -H 'accept: application/dns-json' \
        'https://cloudflare-dns.com/dns-query?name=example.com&type=A' 2>/dev/null | grep -q '"Status"'; then
        DOH_PROVIDER="cloudflare"
    elif curl --max-time 5 -s -H 'accept: application/dns-json' \
        'https://dns.quad9.net/dns-query?name=example.com&type=A' 2>/dev/null | grep -q '"Status"'; then
        DOH_PROVIDER="quad9"
    fi
fi

echo -e "${GREEN}[5/7] Configuring DNS over TLS ($DOH_PROVIDER)...${NC}"
mkdir -p /etc/systemd/resolved.conf.d
if [ "$DOH_PROVIDER" = "cloudflare" ]; then
    cat > /etc/systemd/resolved.conf.d/99-net-set.conf <<'EOF'
[Resolve]
DNS=1.1.1.1 1.0.0.1 2606:4700:4700::1111 2606:4700:4700::1001
DNSOverTLS=yes
DNSSEC=allow-downgrade
Cache=yes
EOF
else
    cat > /etc/systemd/resolved.conf.d/99-net-set.conf <<'EOF'
[Resolve]
DNS=9.9.9.9 149.112.112.112 2620:fe::fe 2620:fe::9
DNSOverTLS=yes
DNSSEC=allow-downgrade
Cache=yes
EOF
fi

ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
systemctl enable systemd-resolved >/dev/null 2>&1
systemctl restart systemd-resolved >/dev/null 2>&1

echo -e "${GREEN}[6/7] Validating DNS...${NC}"
sleep 2
if ! nslookup example.com >/dev/null 2>&1; then
    echo -e "${RED}DNS validation failed!${NC}"
    exit 1
fi

echo -e "${GREEN}[7/7] Running tests...${NC}"
echo -n "  Testing connectivity... "
if ping -c 2 -W 3 1.1.1.1 >/dev/null 2>&1; then
    echo -e "${GREEN}OK${NC}"
else
    echo -e "${YELLOW}WARN${NC}"
fi

echo -n "  Testing censorship... "
if command -v curl >/dev/null 2>&1; then
    tmpfile=$(mktemp)
    if curl -s --max-time 10 https://rutube.ru > "$tmpfile" 2>/dev/null; then
        if grep -qi 'lang="ru"' "$tmpfile" 2>/dev/null; then
            echo -e "${GREEN}No censorship detected${NC}"
        else
            echo -e "${YELLOW}Check needed${NC}"
        fi
    else
        echo -e "${YELLOW}Connection failed${NC}"
    fi
    rm -f "$tmpfile"
else
    echo -e "${YELLOW}curl not available${NC}"
fi

echo
echo -e "${GREEN}=== Configuration Complete ===${NC}"
echo "DNS Server: $(resolvectl status 2>/dev/null | grep 'Current DNS Server' | awk '{print $4}' || echo 'unknown')"
echo "DNS over TLS: Enabled"
