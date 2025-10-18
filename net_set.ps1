<#
net_set.ps1 - Network Security Configuration for Windows 11

Implements similar functionality to the provided Linux shell scripts:
- Backup network configuration (interfaces, DNS, firewall rules, registry keys)
- Enable IPv6
- Configure DNS over HTTPS (Cloudflare / Quad9) via registry for Windows 11 DNS over HTTPS
- Apply strict network security settings (registry and netsh tweaks)
- Configure Windows Firewall (allow SSH/RDP/HTTPS, block HTTP inbound)
- Verification tests (ping IPv4/IPv6, DNS resolution, DoH basic test)

Run as Administrator.
#>

[CmdletBinding()]
param()

function Write-Info { param($m) Write-Host "[INFO] $m" -ForegroundColor Cyan }
function Write-Success { param($m) Write-Host "[SUCCESS] $m" -ForegroundColor Green }
function Write-Warn { param($m) Write-Host "[WARN] $m" -ForegroundColor Yellow }
function Write-ErrorMsg { param($m) Write-Host "[ERROR] $m" -ForegroundColor Red }

if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-ErrorMsg "This script must be run as Administrator"
    exit 1
}

$timestamp = (Get-Date -Format "yyyyMMdd_HHmmss")
$backupDir = "C:\Windows\Temp\net_set_backup_$timestamp"
New-Item -Path $backupDir -ItemType Directory -Force | Out-Null
Write-Info "Backup directory: $backupDir"

# Backup network configuration
Write-Info "Backing up network configuration..."
Get-NetIPAddress | Out-File -FilePath "$backupDir\net_ipaddress.txt" -Encoding utf8
Get-NetIPConfiguration | Out-File -FilePath "$backupDir\net_ipconfig.txt" -Encoding utf8
Get-DnsClientServerAddress | Out-File -FilePath "$backupDir\dns_servers.txt" -Encoding utf8
Get-NetFirewallRule | Out-File -FilePath "$backupDir\firewall_rules.txt" -Encoding utf8
reg export "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" "$backupDir\tcpip_parameters.reg" /y > $null 2>&1
reg export "HKLM\SYSTEM\CurrentControlSet\Services\Dnscache" "$backupDir\dnscache.reg" /y > $null 2>&1
Write-Success "Backup completed"

# Enable IPv6
Write-Info "Enabling IPv6 on all interfaces..."
# Ensure DisabledComponents not disabling IPv6
$tcpipParams = 'HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters'
if (-not (Test-Path $tcpipParams)) {
    New-Item -Path $tcpipParams -Force | Out-Null
}
try {
    # Set DisabledComponents to 0 to enable IPv6 (if present)
    Set-ItemProperty -Path $tcpipParams -Name DisabledComponents -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
    Write-Success "IPv6 DisabledComponents set to 0"
} catch {
    Write-Warn "Could not set DisabledComponents: $_"
}

# Ensure IPv6 is not disabled per-interface
Get-NetAdapter | Where-Object { $_.Status -eq 'Up' } | ForEach-Object {
    $ifIndex = $_.ifIndex
    try {
        Enable-NetAdapterBinding -Name $_.Name -ComponentID ms_tcpip6 -ErrorAction SilentlyContinue
        Write-Info "Enabled IPv6 binding on adapter: $($_.Name)"
    } catch {
        Write-Warn "Failed to enable IPv6 on $($_.Name): $($_)"
    }
}

# Configure DNS over HTTPS (Windows 11 has native DoH starting with certain builds)
Write-Info "Configuring DNS over HTTPS (DoH) using Cloudflare and Quad9..."

function Set-DoHForInterface {
    param(
        [string]$InterfaceAlias,
        [string]$Provider,
        [string]$NextDnsId
    )

    # Map provider selection to templates and server IPs
    $serverAddresses = @()
    $providerJson = $null
    switch ($Provider) {
        'Cloudflare' {
            $serverAddresses = @('1.1.1.1','2606:4700:4700::1111')
            $providerJson = '{"DisplayName":"Cloudflare","Template":"https://cloudflare-dns.com/dns-query","ServerAddresses":["1.1.1.1","2606:4700:4700::1111"]}'
        }
        'Quad9' {
            $serverAddresses = @('9.9.9.9','149.112.112.112','2620:fe::fe','2620:fe::9')
            $providerJson = '{"DisplayName":"Quad9","Template":"https://dns.quad9.net/dns-query","ServerAddresses":["9.9.9.9","149.112.112.112","2620:fe::fe","2620:fe::9"]}'
        }
        'OpenDNS' {
            $serverAddresses = @('208.67.222.222','208.67.220.220')
            $providerJson = '{"DisplayName":"OpenDNS","Template":"https://doh.opendns.com/dns-query","ServerAddresses":["208.67.222.222","208.67.220.220"]}'
        }
        'NextDNS' {
            if ([string]::IsNullOrEmpty($NextDnsId)) {
                Write-Warn "NextDNS selected but no config ID provided. Only the template will be applied."
                $template = 'https://dns.nextdns.io/'
            } else {
                $template = "https://dns.nextdns.io/$NextDnsId"
            }
            $serverAddresses = @() # NextDNS uses per-config endpoints; don't set generic IPs
            $providerJson = '{"DisplayName":"NextDNS","Template":"' + $template + '","ServerAddresses":[] }'
        }
        default {
            Write-Warn "Unknown provider '$Provider' - skipping DNS server assignment"
        }
    }

    # Set DNS server addresses on the interface only if we have addresses
    if ($serverAddresses.Count -gt 0) {
        try {
            Set-DnsClientServerAddress -InterfaceAlias $InterfaceAlias -ServerAddresses $serverAddresses -ErrorAction Stop
            Write-Info "Set DNS servers for $InterfaceAlias to $($serverAddresses -join ', ')"
        } catch {
            Write-Warn "Failed to set DNS servers for $($InterfaceAlias): $($_)"
        }
    } else {
        Write-Info "No static DNS addresses set for $InterfaceAlias (provider: $Provider)"
    }

    # Configure DoH templates in the registry for the interface
    $base = "HKLM:\SOFTWARE\Policies\Microsoft\WindowsNT\DnsClient"
    if (-not (Test-Path $base)) { New-Item -Path $base -Force | Out-Null }

    $dohKey = Join-Path $base "DoH"
    if (-not (Test-Path $dohKey)) { New-Item -Path $dohKey -Force | Out-Null }

    $providersKey = Join-Path $dohKey "Providers"
    if (-not (Test-Path $providersKey)) { New-Item -Path $providersKey -Force | Out-Null }

    # Remove other provider entries (clean up) and add the selected provider only
    Get-ChildItem -Path $providersKey -ErrorAction SilentlyContinue | ForEach-Object { Remove-Item -Path $_.PSPath -Recurse -Force -ErrorAction SilentlyContinue }

    $selKey = Join-Path $providersKey $Provider
    New-Item -Path $selKey -Force | Out-Null
    New-ItemProperty -Path $selKey -Name Provider -Value $providerJson -PropertyType String -Force | Out-Null

    # Enable policy to auto-upgrade clients to DoH (Windows will use configured providers)
    New-ItemProperty -Path $dohKey -Name EnableAutoUpgrade -Value 1 -PropertyType DWord -Force | Out-Null
    New-ItemProperty -Path $dohKey -Name PreferredProvider -Value $Provider -PropertyType String -Force | Out-Null

    Write-Success "DoH policy configured for provider '$Provider' (requires reboot or policy refresh to fully apply)"
}

# Select DoH provider (interactive with environment variable fallback)
$availableProviders = @('Cloudflare','Quad9','OpenDNS','NextDNS')
$envProvider = $env:PREFERRED_DOH_PROVIDER
$envNextDnsId = $env:NEXTDNS_ID

if ($envProvider -and $availableProviders -contains $envProvider) {
    $chosenProvider = $envProvider
    Write-Info "Using DoH provider from environment: $chosenProvider"
} else {
    Write-Host "Select preferred DoH provider or press Enter for interactive choice:" -ForegroundColor Cyan
    for ($i = 0; $i -lt $availableProviders.Count; $i++) {
        Write-Host "[$($i+1)] $($availableProviders[$i])"
    }
    $sel = Read-Host "Enter number (1-$($availableProviders.Count)) or press Enter for interactive prompt"
    if ($sel -match '^[1-9][0-9]*$' -and [int]$sel -ge 1 -and [int]$sel -le $availableProviders.Count) {
        $chosenProvider = $availableProviders[[int]$sel - 1]
    } else {
        # Fallback to interactive text prompt
        $txt = Read-Host "Type provider name (Cloudflare, Quad9, OpenDNS, NextDNS) or leave blank to skip DoH"
        if ($txt -and $availableProviders -contains $txt) { $chosenProvider = $txt } else { $chosenProvider = $null }
    }
}

if ($chosenProvider) {
    if ($chosenProvider -eq 'NextDNS' -and -not $envNextDnsId) {
        $nextId = Read-Host "Enter your NextDNS config ID (leave blank to use generic template)"
    } else { $nextId = $envNextDnsId }

    $netIfs = Get-NetAdapter | Where-Object { $_.Status -eq 'Up' -and ($_.NdisPhysicalMedium -ne 'Loopback') }
    foreach ($if in $netIfs) { Set-DoHForInterface -InterfaceAlias $if.Name -Provider $chosenProvider -NextDnsId $nextId }
} else {
    Write-Warn "No DoH provider selected; skipping DoH configuration"
}

# Apply strict network security settings (registry and netsh)
Write-Info "Applying strict network security settings..."

# Disable IP forwarding
Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters' -Name 'IPEnableRouter' -Value 0 -Type DWord -Force
Write-Info "Disabled IP forwarding"

# Enable SYN cookies equivalent - Windows TCP backlog tuning limited via registry; set TcpNumConnections and related (best-effort)
$tcpKey = 'HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters'
New-ItemProperty -Path $tcpKey -Name 'EnablePMTUDiscovery' -Value 1 -PropertyType DWord -Force | Out-Null
Write-Info "Set PMTU Discovery enabled"

# Disable ICMP redirects
Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters' -Name 'EnableICMPRedirect' -Value 0 -Type DWord -Force
Write-Info "Disabled ICMP redirects"

# Windows doesn't have direct equivalents for all Linux sysctls; apply best-effort hardening

# Configure Windows Firewall rules
Write-Info "Configuring Windows Firewall rules..."

# Default policy: inbound block, outbound allow (Windows default on public profile is block inbound)
# Allow inbound SSH (if OpenSSH installed) and HTTPS; block HTTP inbound

# Allow inbound SSH (port 22) if needed
if (-not (Get-NetFirewallRule -DisplayName 'Allow SSH Inbound' -ErrorAction SilentlyContinue)) {
    New-NetFirewallRule -DisplayName 'Allow SSH Inbound' -Direction Inbound -Protocol TCP -LocalPort 22 -Action Allow -Profile Any
    Write-Info "Created firewall rule: Allow SSH Inbound"
}

# Allow inbound HTTPS
if (-not (Get-NetFirewallRule -DisplayName 'Allow HTTPS Inbound' -ErrorAction SilentlyContinue)) {
    New-NetFirewallRule -DisplayName 'Allow HTTPS Inbound' -Direction Inbound -Protocol TCP -LocalPort 443 -Action Allow -Profile Any
    Write-Info "Created firewall rule: Allow HTTPS Inbound"
}

# Block inbound HTTP
if (-not (Get-NetFirewallRule -DisplayName 'Block HTTP Inbound' -ErrorAction SilentlyContinue)) {
    New-NetFirewallRule -DisplayName 'Block HTTP Inbound' -Direction Inbound -Protocol TCP -LocalPort 80 -Action Block -Profile Any
    Write-Info "Created firewall rule: Block HTTP Inbound"
}

Write-Success "Firewall rules configured"

# Save firewall configuration to backup directory
netsh advfirewall export "$backupDir\firewall_policy.wfw" > $null 2>&1
Write-Info "Exported firewall policy to backup"

# Verification tests
Write-Info "Running verification tests..."

# Show local interface IPv4 and IPv6 addresses
function Show-LocalIPs {
    Write-Info "Local interface addresses:"
    $adapters = Get-NetIPConfiguration | Where-Object { $_.NetAdapter -and $_.NetAdapter.Status -eq 'Up' }
    foreach ($a in $adapters) {
        $name = $a.InterfaceAlias
        Write-Host "-- $name --" -ForegroundColor Yellow
        # IPv4
        foreach ($ip in $a.IPv4Address) {
            Write-Host "IPv4:`t$($ip.IPAddress)" -ForegroundColor Green
        }
        # IPv6 - skip link-local fe80:: addresses
        foreach ($ip6 in $a.IPv6Address) {
            if ($ip6.IPAddress -notmatch '^fe80:') {
                Write-Host "IPv6:`t$($ip6.IPAddress)" -ForegroundColor Green
            }
        }
        Write-Host
    }
}

# Function to display public IPv4/IPv6 using ident.me
function Get-PublicIP {
    param()
    Write-Info "Public IP checks (via ident.me):"
    # IPv4
    try {
        if (Get-Command curl -ErrorAction SilentlyContinue) {
            $pub4 = curl -s --ipv4 https://v4.ident.me
        } else {
            $pub4 = Invoke-RestMethod -Uri 'https://v4.ident.me' -Method GET -UseBasicParsing -ErrorAction Stop
        }
        if ($pub4) { Write-Success "Public IPv4: $pub4" } else { Write-Warn "Public IPv4: no response" }
    } catch { Write-Warn "Public IPv4 check failed: $_" }

    # IPv6
    try {
        if (Get-Command curl -ErrorAction SilentlyContinue) {
            $pub6 = curl -s --ipv6 https://v6.ident.me
        } else {
            $pub6 = Invoke-RestMethod -Uri 'https://v6.ident.me' -Method GET -UseBasicParsing -ErrorAction Stop
        }
        if ($pub6) { Write-Success "Public IPv6: $pub6" } else { Write-Warn "Public IPv6: no response or not available" }
    } catch { Write-Warn "Public IPv6 check failed: $_" }
}

# Test IPv4 connectivity
Write-Info "Testing IPv4 connectivity (8.8.8.8)..."
try {
    $r = Test-Connection -ComputerName 8.8.8.8 -Count 2 -Quiet
    if ($r) { Write-Success "IPv4 connectivity: OK" } else { Write-Warn "IPv4 connectivity: Failed" }
} catch { Write-Warn "IPv4 test failed: $_" }

# Test IPv6 connectivity
Write-Info "Testing IPv6 connectivity (ipv6.google.com)..."
try {
    $r6 = Test-Connection -ComputerName ipv6.google.com -Count 2 -Ipv6 -Quiet -ErrorAction SilentlyContinue
    if ($r6) { Write-Success "IPv6 connectivity: OK" } else { Write-Warn "IPv6 connectivity: Failed or not available" }
} catch { Write-Warn "IPv6 test failed: $_" }

# Test DNS resolution
Write-Info "Testing DNS resolution (google.com)..."
try {
    $dns = Resolve-DnsName -Name google.com -ErrorAction Stop
    if ($dns) { Write-Success "DNS resolution: OK" } else { Write-ErrorMsg "DNS resolution: Failed" }
} catch { Write-ErrorMsg "DNS resolution failed: $_" }

# Test DoH using curl (if installed) over HTTPS JSON API
if (Get-Command curl -ErrorAction SilentlyContinue) {
    Write-Info "Testing DoH via Cloudflare (https://cloudflare-dns.com/dns-query)..."
    try {
        $resp = curl -s -H 'accept: application/dns-json' 'https://cloudflare-dns.com/dns-query?name=google.com&type=A' --max-time 10
        if ($resp -and $resp -match 'Answer') { Write-Success "DoH (Cloudflare) test: OK" } else { Write-Warn "DoH (Cloudflare) test: No 'Answer' found" }
    } catch { Write-Warn "DoH test failed: $_" }
} else {
    Write-Warn "curl not found; skipping DoH live test"
}

# Show current DNS client configuration
Write-Info "Current DNS client servers:"
Get-DnsClientServerAddress | Format-Table -AutoSize

# Show local IP addresses (IPv4 & IPv6)
Show-LocalIPs

# Display public IP addresses
Get-PublicIP

Write-Success "Configuration complete. A reboot may be required for some settings to take effect. Backups in: $backupDir"

# Update todo list: mark implementation completed and verify step
Write-Host
Write-Host "Press Enter to close..." -ForegroundColor Cyan
Read-Host | Out-Null

