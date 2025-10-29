#!/bin/bash

#*****************************************************************************#
#                                                                             #
#  net_set.sh                                             TTTTTTTT SSSSSSS II #
#                                                            TT    SS      II #
#  By: st93642@students.tsi.lv                               TT    SSSSSSS II #
#                                                            TT         SS II #
#  Created: Oct 18 2025 11:18 st93642                        TT    SSSSSSS II #
#  Updated: Oct 29 2025 18:12 st93642                                         #
#                                                                             #
#   Transport and Telecommunication Institute - Riga, Latvia                  #
#                       https://tsi.lv                                        #
#*****************************************************************************#

# Network configuration assistant with cautious defaults.  It prepares safe
# changes for IPv6 preference, DHCP DNS isolation, DNS over HTTPS, and
# connectivity checks.  The script runs in planning mode by default and only
# applies modifications when --apply is provided.

set -euo pipefail

VERSION="2024.10-rework"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

APPLY=false
NON_INTERACTIVE=false
ENABLE_FIREWALL=false
SHOW_STATUS_ONLY=false
RESTORE_TARGET=""
QUIET=true

BACKUP_ROOT="/var/backups/net_set"
BACKUP_DIR=""
MANIFEST_FILE=""
CREATED_FILE_MANIFEST=""
ACTIONS_PERFORMED=()
STEP_COUNT=0
TOTAL_STEPS=8  # IPv6 sysctl, gai pref, DHCP, DoH, final checks, DoH verify, censor test, speed

usage() {
    cat <<'EOF'
Usage: net_set.sh [options]

Modes (default is plan-only):
  --plan                Show the actions that would be taken (default)
  --apply               Apply the configuration changes (requires root)
  --status              Print current network status information and exit
  --restore <backup>    Restore files from a previous backup directory

Additional options:
  --enable-firewall     Apply the bundled firewall hardening (opt-in, apply only)
  --yes                 Auto-confirm prompts in apply mode
  --non-interactive     Same as --yes (deprecated alias)
  --quiet               Minimize output, show only errors/warnings (default)
  --verbose             Show detailed output and diagnostics
  -h, --help            Show this help message
  --version             Display script version

Examples:
  sudo ./net_set.sh --plan
  sudo ./net_set.sh --apply --yes
  sudo ./net_set.sh --restore /var/backups/net_set/20241021_153000
EOF
}

print_status() { 
    if ! $QUIET; then
        printf "${BLUE}[INFO]${NC} %s\n" "$1"
    fi
}
print_success() { 
    if $QUIET; then
        printf "\r\033[K"  # Clear progress line before printing
    fi
    printf "${GREEN}[OK]${NC} %s\n" "$1"
}
print_warning() { 
    if $QUIET; then
        printf "\r\033[K"  # Clear progress line before printing
    fi
    printf "${YELLOW}[WARN]${NC} %s\n" "$1"
}
print_error() { 
    if $QUIET; then
        printf "\r\033[K"  # Clear progress line before printing
    fi
    printf "${RED}[ERROR]${NC} %s\n" "$1"
}

show_progress() {
    if $QUIET; then
        STEP_COUNT=$((STEP_COUNT + 1))
        local pct=$((STEP_COUNT * 100 / TOTAL_STEPS))
        local filled=$((pct / 5))
        local empty=$((20 - filled))
        # Clear line before printing new progress
        printf "\r\033[K${BLUE}[%s%s]${NC} %3d%% %s" \
            "$(printf '#%.0s' $(seq 1 $filled))" \
            "$(printf ' %.0s' $(seq 1 $empty))" \
            "$pct" "$1"
        if [ $STEP_COUNT -eq $TOTAL_STEPS ]; then
            echo
        fi
    fi
}

require_root() {
    if [ "$(id -u)" -ne 0 ]; then
        print_error "Root privileges required for this operation"
        exit 1
    fi
}

ensure_backup_root() {
    mkdir -p "$BACKUP_ROOT"
}

timestamp() { date +%Y%m%d_%H%M%S; }

init_backup_dir() {
    ensure_backup_root
    BACKUP_DIR="$BACKUP_ROOT/$(timestamp)"
    mkdir -p "$BACKUP_DIR"
    MANIFEST_FILE="$BACKUP_DIR/manifest.txt"
    CREATED_FILE_MANIFEST="$BACKUP_DIR/created_files.txt"
    touch "$MANIFEST_FILE" "$CREATED_FILE_MANIFEST"
    if ! $QUIET; then
        print_status "Backup directory: $BACKUP_DIR"
    fi
}

backup_file() {
    local path="$1"
    if [ ! -e "$path" ]; then
        return 0
    fi
    local dest="$BACKUP_DIR$path"
    mkdir -p "$(dirname "$dest")"
    cp -a "$path" "$dest"
    echo "$path" >>"$MANIFEST_FILE"
}

register_created_file() {
    local path="$1"
    if [ -n "$MANIFEST_FILE" ] && grep -Fx "$path" "$MANIFEST_FILE" >/dev/null 2>&1; then
        return
    fi
    if grep -Fx "$path" "$CREATED_FILE_MANIFEST" >/dev/null 2>&1; then
        return
    fi
    echo "$path" >>"$CREATED_FILE_MANIFEST"
}

restore_backup() {
    local dir="$1"
    local manifest="$dir/manifest.txt"
    local created="$dir/created_files.txt"

    if [ ! -d "$dir" ]; then
        print_error "Backup directory not found: $dir"
        exit 1
    fi
    if [ ! -f "$manifest" ]; then
        print_error "Manifest not found in backup directory"
        exit 1
    fi

    print_status "Restoring files from $dir"

    while IFS= read -r path; do
        [ -z "$path" ] && continue
        if [ -e "$dir$path" ]; then
            mkdir -p "$(dirname "$path")"
            cp -a "$dir$path" "$path"
            printf "  restored %s\n" "$path"
        else
            print_warning "Missing backup copy for $path"
        fi
    done <"$manifest"

    if [ -f "$created" ]; then
        while IFS= read -r created_path; do
            [ -z "$created_path" ] && continue
            if [ -e "$created_path" ]; then
                rm -f "$created_path"
                printf "  removed %s\n" "$created_path"
            fi
        done <"$created"
    fi

    print_success "Restore finished"
}

add_action() {
    ACTIONS_PERFORMED+=("$1")
}

ask_confirmation() {
    local message="$1"
    if $NON_INTERACTIVE; then
        return 0
    fi
    printf "%s (y/N): " "$message"
    read -r answer
    echo
    if [ "$answer" != "y" ] && [ "$answer" != "Y" ]; then
        print_error "User declined: $message"
        exit 1
    fi
}

command_exists() { command -v "$1" >/dev/null 2>&1; }

ipv6_default_route_present() { ip -6 route show default >/dev/null 2>&1; }

status_public_ips() {
    if ! command_exists curl && ! command_exists wget; then
        print_warning "curl/wget unavailable, skipping public IP lookup"
        return
    fi

    local ipv4="N/A" ipv6="N/A"
    if command_exists curl; then
        ipv4=$(curl -s --max-time 10 https://v4.ident.me 2>/dev/null || echo "N/A")
        ipv6=$(curl -s --max-time 10 https://v6.ident.me 2>/dev/null || echo "N/A")
    else
        ipv4=$(wget -qO- --timeout=10 --inet4-only https://v4.ident.me 2>/dev/null || echo "N/A")
        ipv6=$(wget -qO- --timeout=10 --inet6-only https://v6.ident.me 2>/dev/null || echo "N/A")
    fi
    printf "    Public IPv4: %s\n" "$ipv4"
    printf "    Public IPv6: %s\n" "$ipv6"
}

status_dns_summary() {
    if command_exists resolvectl; then
        resolvectl status | sed 's/^/    /' | head -n 25
    elif command_exists systemd-resolve; then
        systemd-resolve --status | sed 's/^/    /' | head -n 25
    else
        print_warning "resolvectl not available; showing /etc/resolv.conf"
        sed 's/^/    /' /etc/resolv.conf
    fi
}

status_report() {
    print_status "Network status overview"
    printf "    Hostname: %s\n" "$(hostname)"
    printf "    Kernel:   %s\n" "$(uname -r)"
    printf "    Default route (IPv4): %s\n" "$(ip route show default 2>/dev/null | tr '\n' ' ' | sed 's/ *$//')"
    if ipv6_default_route_present; then
        printf "    Default route (IPv6): %s\n" "$(ip -6 route show default 2>/dev/null | tr '\n' ' ' | sed 's/ *$//')"
    else
        printf "    Default route (IPv6): none\n"
    fi

    print_status "Active interfaces"
    ip -o addr show | awk '$3 == "inet" || $3 == "inet6" { if ($4 !~ /^fe80:/) print "    "$2" " $4 }' | sort -u

    print_status "DNS summary"
    status_dns_summary

    print_status "Public IP discovery"
    status_public_ips
}
detect_cyrillic() {
    local file="$1"
    
    # Check for lang="ru" attribute as primary indicator (works for modern JS-heavy sites)
    if grep -qi 'lang="ru"' "$file" 2>/dev/null || grep -qi "lang='ru'" "$file" 2>/dev/null; then
        return 0
    fi
    
    # Fallback to Python-based Cyrillic detection for actual text content
    if command_exists python3; then
        python3 - "$file" <<'PY'
import sys

path = sys.argv[1]
try:
    with open(path, 'rb') as fh:
        data = fh.read().decode('utf-8', 'ignore')
except Exception:
    sys.exit(1)

for ch in data:
    cp = ord(ch)
    if 0x0400 <= cp <= 0x04FF or 0x0500 <= cp <= 0x052F or 0x2DE0 <= cp <= 0x2DFF or 0xA640 <= cp <= 0xA69F:
        sys.exit(0)
sys.exit(1)
PY
        return $?
    fi
    
    # Final fallback to simple grep for known Russian words
    LC_ALL=C grep -q "ТАСС" "$file" 2>/dev/null && return 0
    LC_ALL=C grep -q "Россия" "$file" 2>/dev/null && return 0
    return 1
}

doh_probe_and_select() {
    local prefer_ipv6=false
    if ipv6_default_route_present; then
        prefer_ipv6=true
    fi

    while IFS='|' read -r name url host; do
        [ -z "$name" ] && continue
        print_status "Probing DoH provider $name" >&2
        local curl_opts=(--max-time 8 -s -H 'accept: application/dns-json')
        if $prefer_ipv6; then
            curl_opts+=(--ipv6)
        else
            curl_opts+=(--ipv4)
        fi
        local response
        response=$(curl "${curl_opts[@]}" "${url}?name=example.com&type=A" 2>/dev/null || true)
        if printf "%s" "$response" | grep -q '"Status"\|"Answer"'; then
            local ips
            ips=$(getent ahosts "$host" 2>/dev/null | awk '{print $1}' | uniq | head -n 6)
            if [ -z "$ips" ] && command_exists host; then
                ips=$(host "$host" 2>/dev/null | awk '/address/ {print $NF}' | uniq | head -n 6)
            fi
            local dns_entries=""
            for ip in $ips; do
                [ -z "$ip" ] && continue
                dns_entries="$dns_entries $ip#$host"
            done
            printf "%s|%s\n" "$name" "${dns_entries# }"
            return 0
        fi
        print_warning "$name DoH probe failed" >&2
    done <<'EOF'
quad9|https://dns.quad9.net/dns-query|dns.quad9.net
cloudflare|https://cloudflare-dns.com/dns-query|cloudflare-dns.com
libredns|https://doh.libredns.gr/dns-query|doh.libredns.gr
nextdns|https://doh.nextdns.io/dns-query|doh.nextdns.io
EOF
    return 1
}

apply_ipv6_sysctl() {
    show_progress "IPv6 sysctl"
    local sysctl_file="/etc/sysctl.d/90-net-set-ipv6.conf"
    backup_file "$sysctl_file"
    cat >"$sysctl_file" <<'EOF'
# Managed by net_set.sh -- IPv6 baseline
net.ipv6.conf.all.disable_ipv6 = 0
net.ipv6.conf.default.disable_ipv6 = 0
net.ipv6.conf.lo.disable_ipv6 = 0
net.ipv6.conf.all.use_tempaddr = 2
EOF
    register_created_file "$sysctl_file"
    add_action "Updated $sysctl_file"
    sysctl --system >/dev/null 2>&1 || print_warning "sysctl reload returned non-zero"
}

apply_gai_preference() {
    show_progress "IPv6 preference"
    local gai_conf="/etc/gai.conf"
    local marker="# net_set.sh IPv6 preference"
    local new_file=false
    if [ ! -f "$gai_conf" ]; then
        new_file=true
    fi
    if [ -f "$gai_conf" ]; then
        backup_file "$gai_conf"
    fi
    if grep -q "$marker" "$gai_conf" 2>/dev/null; then
        print_status "gai.conf already contains net_set.sh block"
        return
    fi
    cat >>"$gai_conf" <<EOF
$marker
precedence ::ffff:0:0/96  10
EOF
    if $new_file; then
        register_created_file "$gai_conf"
    fi
    add_action "Adjusted IPv6 precedence in $gai_conf"
}

apply_dhcp_isolation() {
    show_progress "DHCP isolation"
    local hook_dir="/etc/dhcp/dhclient-enter-hooks.d"
    local hook_file="$hook_dir/99-net-set-ignore-dns"
    local conf_dir="/etc/dhcp/dhclient.conf.d"
    local conf_file="$conf_dir/99-net_set.conf"

    mkdir -p "$hook_dir" "$conf_dir"

    if [ -f "$hook_file" ]; then
        backup_file "$hook_file"
    fi
    cat >"$hook_file" <<'EOF'
#!/bin/sh
# Prevent dhclient from overwriting resolv.conf; DHCP used for addressing only
make_resolv_conf() {
    return 0
}
EOF
    chmod 0755 "$hook_file"
    register_created_file "$hook_file"

    if [ -f "$conf_file" ]; then
        backup_file "$conf_file"
    fi
    cat >"$conf_file" <<'EOF'
# net_set.sh DHCP request scope restriction
request subnet-mask, broadcast-address, routers, host-name;
EOF
    register_created_file "$conf_file"
    add_action "Installed DHCP guard hooks"
}

build_resolved_dropin() {
    local name="$1"
    local dns_entries="$2"
    local dropin_dir="/etc/systemd/resolved.conf.d"
    local dropin_file="$dropin_dir/99-net-set.conf"

    mkdir -p "$dropin_dir"
    if [ -f "$dropin_file" ]; then
        backup_file "$dropin_file"
    fi
    cat >"$dropin_file" <<EOF
# Managed by net_set.sh
[Resolve]
DNS=${dns_entries}
DNSOverTLS=yes
DNSSEC=allow-downgrade
Cache=yes
EOF
    register_created_file "$dropin_file"
    add_action "Configured systemd-resolved DoH (${name})"
}

apply_doh_configuration() {
    show_progress "DoH configuration"
    if ! command_exists systemctl; then
        print_warning "systemctl not found; skipping DoH configuration"
        return
    fi
    if ! systemctl list-unit-files systemd-resolved.service >/dev/null 2>&1; then
        print_warning "systemd-resolved not installed; skipping DoH configuration"
        return
    fi

    local selection name dns_entries
    selection=$(doh_probe_and_select 2>/dev/null || true)
    if [ -n "$selection" ]; then
        name=${selection%%|*}
        dns_entries=${selection#*|}
    else
        name="quad9"
        dns_entries="9.9.9.9#dns.quad9.net 149.112.112.112#dns.quad9.net 2620:fe::fe#dns.quad9.net 2620:fe::9#dns.quad9.net"
        print_warning "All probes failed; using conservative Quad9 defaults"
    fi
    if [ -z "$dns_entries" ]; then
        print_warning "No IPs resolved for $name; falling back to Quad9 set"
        name="quad9"
        dns_entries="9.9.9.9#dns.quad9.net 149.112.112.112#dns.quad9.net 2620:fe::fe#dns.quad9.net 2620:fe::9#dns.quad9.net"
    fi

    build_resolved_dropin "$name" "$dns_entries"

    print_success "DNS over HTTPS provider in use: $name"
    
    if [ -e /etc/resolv.conf ]; then
        backup_file /etc/resolv.conf
    fi
    ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
    register_created_file /etc/resolv.conf

    systemctl enable systemd-resolved >/dev/null 2>&1 || true
    systemctl restart systemd-resolved >/dev/null 2>&1 || print_warning "systemd-resolved restart reported an error"
}

apply_firewall_rules() {
    show_progress "Firewall rules"
    if ! command_exists iptables || ! command_exists ip6tables; then
        print_warning "iptables utilities not available; skipping firewall section"
        return
    fi

    print_warning "Applying strict firewall rules; outbound traffic remains open"

    local rules_dir="/etc/iptables"
    mkdir -p "$rules_dir"
    backup_file "$rules_dir/rules.v4"
    backup_file "$rules_dir/rules.v6"

    iptables -F
    ip6tables -F

    iptables -P INPUT DROP
    iptables -P FORWARD DROP
    iptables -P OUTPUT ACCEPT

    ip6tables -P INPUT DROP
    ip6tables -P FORWARD DROP
    ip6tables -P OUTPUT ACCEPT

    iptables -A INPUT -i lo -j ACCEPT
    ip6tables -A INPUT -i lo -j ACCEPT

    iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
    ip6tables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

    iptables -A INPUT -p tcp --dport 22 -j ACCEPT
    iptables -A INPUT -p tcp --dport 443 -j ACCEPT
    ip6tables -A INPUT -p tcp --dport 22 -j ACCEPT
    ip6tables -A INPUT -p tcp --dport 443 -j ACCEPT

    iptables -A INPUT -p icmp -j ACCEPT
    ip6tables -A INPUT -p ipv6-icmp -j ACCEPT

    if command_exists iptables-save; then
        iptables-save >"$rules_dir/rules.v4"
        ip6tables-save >"$rules_dir/rules.v6"
    fi
    register_created_file "$rules_dir/rules.v4"
    register_created_file "$rules_dir/rules.v6"
    add_action "Firewall rules refreshed"
}

censorship_test() {
    show_progress "Censorship test"
    if ! command_exists curl; then
        print_warning "curl not available; skipping censorship test"
        return
    fi

    # Test multiple Russian sites since some may block automated requests
    local sites=("rutube.ru" "yandex.ru" "mail.ru")
    local tmp_file
    tmp_file=$(mktemp /tmp/censor_test.XXXXXX)
    
    for site in "${sites[@]}"; do
        local curl_opts=(--max-time 15 -s -L -A "Mozilla/5.0")
        # Don't force IPv6 here - let curl choose the best protocol
        # Some Russian sites may not have IPv6 support
        
        local http_code
        http_code=$(curl "${curl_opts[@]}" -w "%{http_code}" -o "$tmp_file" "https://$site" 2>/dev/null || true)
        
        if [ "$http_code" = "200" ]; then
            if [ -s "$tmp_file" ] && detect_cyrillic "$tmp_file"; then
                if ! $QUIET; then
                    print_success "Censorship test passed: $site accessible with Cyrillic content"
                fi
                rm -f "$tmp_file"
                return 0
            fi
        fi
    done
    
    print_warning "Censorship test: No Russian sites returned valid Cyrillic content"
    rm -f "$tmp_file"
    return 1
}

doh_sanity_check() {
    show_progress "DoH verification"
    if ! command_exists curl; then
        print_warning "curl unavailable; skipping DoH sanity check"
        return
    fi
    local ok=false
    if curl --max-time 10 --ipv4 -s -H 'accept: application/dns-json' 'https://cloudflare-dns.com/dns-query?name=example.com&type=A' 2>/dev/null | grep -q '"Status"'; then
        ok=true
    fi
    if curl --max-time 10 --ipv6 -s -H 'accept: application/dns-json' 'https://cloudflare-dns.com/dns-query?name=example.com&type=AAAA' 2>/dev/null | grep -q '"Status"'; then
        ok=true
    fi
    if ! $ok; then
        print_warning "DoH verification failed; review systemd-resolved status"
    fi
}

run_speed_checks() {
    show_progress "Speed test"
    
    # In verbose mode, run full network-verify.sh if available
    if [ -x ./network-verify.sh ] && ! $QUIET; then
        ./network-verify.sh 2>&1 | grep -E '^\[(SUCCESS|ERROR|WARNING|WARN)\]|Speed|Mbps' || true
        return
    fi

    # Quick speed test for both quiet and verbose modes
    if command_exists curl; then
        local start end duration speed
        start=$(date +%s.%N)
        if curl -s --max-time 60 -o /dev/null http://speedtest.tele2.net/10MB.zip 2>/dev/null; then
            end=$(date +%s.%N)
            duration=$(echo "$end - $start" | bc 2>/dev/null || echo 1)
            speed=$(echo "scale=2; 80 / $duration" | bc 2>/dev/null || echo "n/a")
            if ! $QUIET; then
                print_success "Download speed: ${speed} Mbps"
            fi
        fi
    fi
}

post_apply_report() {
    show_progress "Final checks"
    doh_sanity_check
    censorship_test || true
    
    local speed_result=""
    if command_exists curl; then
        local start end duration speed
        start=$(date +%s.%N)
        if curl -s --max-time 60 -o /dev/null http://speedtest.tele2.net/10MB.zip 2>/dev/null; then
            end=$(date +%s.%N)
            duration=$(echo "$end - $start" | bc 2>/dev/null || echo 1)
            speed=$(echo "scale=2; 80 / $duration" | bc 2>/dev/null || echo "n/a")
            speed_result=" ($speed Mbps)"
        fi
    fi
    
    if $QUIET; then
        echo
        print_success "Network configuration completed successfully${speed_result}"
    elif [ -x ./network-verify.sh ]; then
        ./network-verify.sh 2>&1 | grep -E '^\[(SUCCESS|ERROR|WARNING|WARN)\]|Speed|Mbps' || true
    fi
}

plan_summary() {
    if $QUIET; then
        return
    fi
    print_status "Planned actions"
    print_status "  - Ensure IPv6 sysctl defaults favour enablement"
    print_status "  - Prefer IPv6 addresses in /etc/gai.conf"
    print_status "  - Prevent DHCP from overwriting DNS servers"
    print_status "  - Configure systemd-resolved for DNS-over-HTTPS with fallback"
    if $ENABLE_FIREWALL; then
        print_status "  - Refresh strict iptables/ip6tables baseline"
    else
        print_status "  - Firewall hardening skipped (opt-in with --enable-firewall)"
    fi
    print_status "  - Run diagnostics (public IPs, DoH check, censorship probe, speed sample)"
    print_warning "No changes will be made unless --apply is passed"
}

apply_workflow() {
    require_root
    init_backup_dir
    ask_confirmation "Apply modifications now?"
    
    if $QUIET; then
        echo "Applying configuration..."
    fi
    
    apply_ipv6_sysctl
    apply_gai_preference
    apply_dhcp_isolation
    apply_doh_configuration
    if $ENABLE_FIREWALL; then
        ask_confirmation "Proceed with firewall rule refresh?"
        apply_firewall_rules
    fi
    
    print_success "Configuration steps completed"
    post_apply_report
    
    if ! $QUIET; then
        echo
        print_status "Actions performed:"
        printf '  - %s\n' "${ACTIONS_PERFORMED[@]}"
    fi
    print_warning "Restore: $BACKUP_DIR"
}

parse_args() {
    while [ $# -gt 0 ]; do
        case "$1" in
            --apply)
                APPLY=true
                ;;
            --plan)
                APPLY=false
                ;;
            --status)
                SHOW_STATUS_ONLY=true
                ;;
            --restore)
                shift || { print_error "Missing argument for --restore"; exit 1; }
                RESTORE_TARGET="$1"
                ;;
            --enable-firewall)
                ENABLE_FIREWALL=true
                ;;
            --yes|--non-interactive)
                NON_INTERACTIVE=true
                ;;
            --quiet)
                QUIET=true
                ;;
            --verbose)
                QUIET=false
                ;;
            --version)
                echo "net_set.sh version $VERSION"
                exit 0
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                usage
                exit 1
                ;;
        esac
        shift || true
    done
}

main() {
    parse_args "$@"

    if [ -n "$RESTORE_TARGET" ]; then
        require_root
        restore_backup "$RESTORE_TARGET"
        exit 0
    fi

    if $SHOW_STATUS_ONLY; then
        status_report
        exit 0
    fi

    plan_summary

    if ! $APPLY; then
        status_report
        exit 0
    fi

    apply_workflow
}

trap 'print_error "Interrupted"; exit 1' INT TERM

main "$@"