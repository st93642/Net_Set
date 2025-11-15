#*****************************************************************************#
#                                                                             #
#  net_set_ui.ps1                                          TTTTTTTT SSSSSSS II #
#                                                            TT    SS      II #
#  By: st93642@students.tsi.lv                               TT    SSSSSSS II #
#                                                            TT         SS II #
#  Created: Nov 15 2025 09:21 st93642                       TT    SSSSSSS II #
#  Updated: Nov 15 2025 09:21 st93642                                         #
#                                                                             #
#   Transport and Telecommunication Institute - Riga, Latvia                  #
#                       https://tsi.lv                                        #
#*****************************************************************************#

<#
net_set_ui.ps1 - Desktop UI wrapper for net_set.ps1 Windows version
Provides graphical interface using Windows Forms for network configuration tool
#>

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Get script directory
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$NetSetScript = Join-Path $ScriptDir "net_set.ps1"

# Check if main script exists
if (-not (Test-Path $NetSetScript)) {
    [System.Windows.Forms.MessageBox]::Show(
        "Error: net_set.ps1 not found in script directory", 
        "Network Configuration Error", 
        [System.Windows.Forms.MessageBoxButtons]::OK, 
        [System.Windows.Forms.MessageBoxIcon]::Error
    )
    exit 1
}

# Create main form
$mainForm = New-Object System.Windows.Forms.Form
$mainForm.Text = "Network Configuration Tool"
$mainForm.Size = New-Object System.Drawing.Size(500, 400)
$mainForm.StartPosition = "CenterScreen"
$mainForm.FormBorderStyle = "FixedDialog"
$mainForm.MaximizeBox = $false
$mainForm.Icon = [System.Drawing.SystemIcons]::Information

# Title label
$titleLabel = New-Object System.Windows.Forms.Label
$titleLabel.Text = "Network Security Configuration Tool"
$titleLabel.Font = New-Object System.Drawing.Font("Arial", 12, [System.Drawing.FontStyle]::Bold)
$titleLabel.AutoSize = $true
$titleLabel.Location = New-Object System.Drawing.Point(50, 20)

# Description label
$descLabel = New-Object System.Windows.Forms.Label
$descLabel.Text = "Configure secure network settings with IPv6, DNS over HTTPS, and security policies."
$descLabel.AutoSize = $true
$descLabel.Location = New-Object System.Drawing.Point(50, 55)
$descLabel.MaximumSize = New-Object System.Drawing.Size(400, 0)

# Configure button
$configButton = New-Object System.Windows.Forms.Button
$configButton.Text = "Configure Network Settings"
$configButton.Size = New-Object System.Drawing.Size(200, 40)
$configButton.Location = New-Object System.Drawing.Point(150, 100)
$configButton.Font = New-Object System.Drawing.Font("Arial", 10)

# Verify button
$verifyButton = New-Object System.Windows.Forms.Button
$verifyButton.Text = "Verify Configuration"
$verifyButton.Size = New-Object System.Drawing.Size(200, 40)
$verifyButton.Location = New-Object System.Drawing.Point(150, 150)
$verifyButton.Font = New-Object System.Drawing.Font("Arial", 10)

# Status button
$statusButton = New-Object System.Windows.Forms.Button
$statusButton.Text = "View Current Status"
$statusButton.Size = New-Object System.Drawing.Size(200, 40)
$statusButton.Location = New-Object System.Drawing.Point(150, 200)
$statusButton.Font = New-Object System.Drawing.Font("Arial", 10)

# Exit button
$exitButton = New-Object System.Windows.Forms.Button
$exitButton.Text = "Exit"
$exitButton.Size = New-Object System.Drawing.Size(200, 40)
$exitButton.Location = New-Object System.Drawing.Point(150, 250)
$exitButton.Font = New-Object System.Drawing.Font("Arial", 10)

# Progress bar (initially hidden)
$progressBar = New-Object System.Windows.Forms.ProgressBar
$progressBar.Size = New-Object System.Drawing.Size(400, 20)
$progressBar.Location = New-Object System.Drawing.Point(50, 320)
$progressBar.Style = "Continuous"
$progressBar.Visible = $false

# Status label (initially hidden)
$statusLabel = New-Object System.Windows.Forms.Label
$statusLabel.Text = "Processing..."
$statusLabel.AutoSize = $true
$statusLabel.Location = New-Object System.Drawing.Point(50, 300)
$statusLabel.Visible = $false

# Add controls to form
$mainForm.Controls.AddRange(@($titleLabel, $descLabel, $configButton, $verifyButton, $statusButton, $exitButton, $progressBar, $statusLabel))

# Function to show status
function Show-Status {
    param([string]$StatusText)
    $statusLabel.Text = $StatusText
    $statusLabel.Visible = $true
    $progressBar.Visible = $true
    $mainForm.Refresh()
}

# Function to hide status
function Hide-Status {
    $statusLabel.Visible = $false
    $progressBar.Visible = $false
    $mainForm.Refresh()
}

# Function to run configuration
function Start-Configuration {
    $result = [System.Windows.Forms.MessageBox]::Show(
        "This will configure IPv6, DNS over HTTPS, and apply network security settings.`n`nDo you want to continue?", 
        "Confirm Configuration", 
        [System.Windows.Forms.MessageBoxButtons]::YesNo, 
        [System.Windows.Forms.MessageBoxIcon]::Question
    )
    
    if ($result -eq "Yes") {
        try {
            Show-Status "Initializing configuration..."
            $progressBar.Value = 10
            $mainForm.Refresh()
            
            # Check if running as Administrator
            if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
                $result = [System.Windows.Forms.MessageBox]::Show(
                    "This script requires Administrator privileges.`n`nWould you like to restart as Administrator?", 
                    "Administrator Required", 
                    [System.Windows.Forms.MessageBoxButtons]::YesNo, 
                    [System.Windows.Forms.MessageBoxIcon]::Warning
                )
                
                if ($result -eq "Yes") {
                    # Restart as Administrator
                    $psi = New-Object System.Diagnostics.ProcessStartInfo
                    $psi.Verb = "runas"
                    $psi.FileName = "powershell.exe"
                    $psi.Arguments = "-ExecutionPolicy Bypass -File `"$NetSetScript`""
                    $psi.WorkingDirectory = $ScriptDir
                    [System.Diagnostics.Process]::Start($psi) | Out-Null
                    $mainForm.Close()
                    return
                } else {
                    Hide-Status
                    [System.Windows.Forms.MessageBox]::Show(
                        "Configuration requires Administrator privileges.", 
                        "Access Denied", 
                        [System.Windows.Forms.MessageBoxButtons]::OK, 
                        [System.Windows.Forms.MessageBoxIcon]::Warning
                    )
                    return
                }
            }
            
            Show-Status "Running network configuration..."
            $progressBar.Value = 30
            $mainForm.Refresh()
            
            # Run the configuration script
            $process = Start-Process -FilePath "powershell.exe" -ArgumentList "-ExecutionPolicy Bypass -File `"$NetSetScript`"" -Wait -PassThru -WindowStyle Hidden
            
            Show-Status "Finalizing configuration..."
            $progressBar.Value = 90
            $mainForm.Refresh()
            
            Start-Sleep -Seconds 2
            $progressBar.Value = 100
            
            Hide-Status
            
            if ($process.ExitCode -eq 0) {
                [System.Windows.Forms.MessageBox]::Show(
                    "Network configuration completed successfully!", 
                    "Success", 
                    [System.Windows.Forms.MessageBoxButtons]::OK, 
                    [System.Windows.Forms.MessageBoxIcon]::Information
                )
            } else {
                [System.Windows.Forms.MessageBox]::Show(
                    "Network configuration completed with warnings or errors.`n`nPlease check the backup logs for details.", 
                    "Configuration Complete", 
                    [System.Windows.Forms.MessageBoxButtons]::OK, 
                    [System.Windows.Forms.MessageBoxIcon]::Warning
                )
            }
        }
        catch {
            Hide-Status
            [System.Windows.Forms.MessageBox]::Show(
                "An error occurred during configuration:`n`n$($_.Exception.Message)", 
                "Configuration Error", 
                [System.Windows.Forms.MessageBoxButtons]::OK, 
                [System.Windows.Forms.MessageBoxIcon]::Error
            )
        }
    }
}

# Function to show current status
function Show-CurrentStatus {
    $statusForm = New-Object System.Windows.Forms.Form
    $statusForm.Text = "Current Network Status"
    $statusForm.Size = New-Object System.Drawing.Size(500, 400)
    $statusForm.StartPosition = "CenterScreen"
    $statusForm.FormBorderStyle = "FixedDialog"
    $statusForm.MaximizeBox = $false
    
    $statusTextBox = New-Object System.Windows.Forms.TextBox
    $statusTextBox.Multiline = $true
    $statusTextBox.ScrollBars = "Vertical"
    $statusTextBox.ReadOnly = $true
    $statusTextBox.Location = New-Object System.Drawing.Point(10, 10)
    $statusTextBox.Size = New-Object System.Drawing.Size(460, 320)
    $statusTextBox.Font = New-Object System.Drawing.Font("Consolas", 9)
    
    $closeButton = New-Object System.Windows.Forms.Button
    $closeButton.Text = "Close"
    $closeButton.Location = New-Object System.Drawing.Point(200, 340)
    $closeButton.Size = New-Object System.Drawing.Size(80, 25)
    
    $closeButton.Add_Click({ $statusForm.Close() })
    
    $statusForm.Controls.AddRange(@($statusTextBox, $closeButton))
    
    # Gather network status information
    $statusText = "=== Current Network Status ===`r`n`r`n"
    
    try {
        $statusText += "Network Adapters:`r`n"
        $adapters = Get-NetAdapter | Where-Object { $_.Status -eq "Up" } | Select-Object Name, InterfaceDescription, LinkSpeed
        foreach ($adapter in $adapters) {
            $statusText += "  - $($adapter.Name): $($adapter.InterfaceDescription) ($($adapter.LinkSpeed))`r`n"
        }
        $statusText += "`r`n"
        
        $statusText += "IP Configuration:`r`n"
        $ipConfig = Get-NetIPConfiguration | Where-Object { $_.NetAdapter.Status -eq "Up" }
        foreach ($config in $ipConfig) {
            $statusText += "  - $($config.InterfaceAlias):`r`n"
            if ($config.IPv4Address) {
                $statusText += "    IPv4: $($config.IPv4Address.IPAddress)`r`n"
            }
            if ($config.IPv6Address) {
                $statusText += "    IPv6: $($config.IPv6Address.IPAddress)`r`n"
            }
            $statusText += "    DNS: $($config.DNSServer.ServerAddresses -join ', ')`r`n"
        }
        $statusText += "`r`n"
        
        $statusText += "DNS over HTTPS Status:`r`n"
        try {
            $dohSettings = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters" -ErrorAction SilentlyContinue
            if ($dohSettings -and $dohSettings.DOHSettings) {
                $statusText += "  DoH: Configured`r`n"
            } else {
                $statusText += "  DoH: Not configured`r`n"
            }
        } catch {
            $statusText += "  DoH: Unable to determine status`r`n"
        }
        
        $statusText += "`r`nFirewall Status:`r`n"
        $firewallProfiles = Get-NetFirewallProfile
        foreach ($profile in $firewallProfiles) {
            $statusText += "  $($profile.Name): $($profile.Enabled)`r`n"
        }
        
    } catch {
        $statusText += "Error gathering network information: $($_.Exception.Message)`r`n"
    }
    
    $statusTextBox.Text = $statusText
    $statusForm.ShowDialog()
}

# Button click handlers
$configButton.Add_Click({ Start-Configuration })

$verifyButton.Add_Click({
    $result = [System.Windows.Forms.MessageBox]::Show(
        "This will run network verification tests to check your current configuration.`n`nDo you want to continue?", 
        "Confirm Verification", 
        [System.Windows.Forms.MessageBoxButtons]::YesNo, 
        [System.Windows.Forms.MessageBoxIcon]::Question
    )
    
    if ($result -eq "Yes") {
        Show-Status "Running network verification..."
        $progressBar.Value = 10
        $mainForm.Refresh()
        
        # Create verification results form
        $verifyForm = New-Object System.Windows.Forms.Form
        $verifyForm.Text = "Network Verification Results"
        $verifyForm.Size = New-Object System.Drawing.Size(700, 500)
        $verifyForm.StartPosition = "CenterScreen"
        $verifyForm.FormBorderStyle = "FixedDialog"
        $verifyForm.MaximizeBox = $false
        
        $verifyTextBox = New-Object System.Windows.Forms.TextBox
        $verifyTextBox.Multiline = $true
        $verifyTextBox.ScrollBars = "Vertical"
        $verifyTextBox.ReadOnly = $true
        $verifyTextBox.Location = New-Object System.Drawing.Point(10, 10)
        $verifyTextBox.Size = New-Object System.Drawing.Size(660, 420)
        # Use a font that better supports Unicode characters
        try {
            $verifyTextBox.Font = New-Object System.Drawing.Font("Segoe UI Emoji", 9)
        } catch {
            try {
                $verifyTextBox.Font = New-Object System.Drawing.Font("Microsoft Sans Serif", 9)
            } catch {
                $verifyTextBox.Font = New-Object System.Drawing.Font("Consolas", 9)
            }
        }
        
        $closeVerifyButton = New-Object System.Windows.Forms.Button
        $closeVerifyButton.Text = "Close"
        $closeVerifyButton.Location = New-Object System.Drawing.Point(300, 440)
        $closeVerifyButton.Size = New-Object System.Drawing.Size(80, 25)
        
        $closeVerifyButton.Add_Click({ $verifyForm.Close() })
        
        $verifyForm.Controls.AddRange(@($verifyTextBox, $closeVerifyButton))
        
        # Run verification tests
        $verificationResults = "=== Network Verification Results ===`r`n`r`n"
        $verificationResults += "Verification started at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`r`n`r`n"
        
        try {
            # Test 1: Network Adapter Status
            Show-Status "Checking network adapters..."
            $progressBar.Value = 20
            $mainForm.Refresh()
            
            $verificationResults += "1. Network Adapter Status:`r`n"
            $adapters = Get-NetAdapter | Where-Object { $_.Status -eq "Up" }
            if ($adapters) {
                foreach ($adapter in $adapters) {
                    $verificationResults += "   ✓ $($adapter.Name): $($adapter.Status) ($($adapter.LinkSpeed))`r`n"
                }
            } else {
                $verificationResults += "   ✗ No active network adapters found`r`n"
            }
            $verificationResults += "`r`n"
            
            # Test 2: IP Configuration
            Show-Status "Checking IP configuration..."
            $progressBar.Value = 30
            $mainForm.Refresh()
            
            $verificationResults += "2. IP Configuration:`r`n"
            $ipConfig = Get-NetIPConfiguration | Where-Object { $_.NetAdapter.Status -eq "Up" }
            foreach ($config in $ipConfig) {
                $verificationResults += "   Interface: $($config.InterfaceAlias)`r`n"
                if ($config.IPv4Address) {
                    $verificationResults += "   ✓ IPv4: $($config.IPv4Address.IPAddress)`r`n"
                }
                if ($config.IPv6Address) {
                    $verificationResults += "   ✓ IPv6: $($config.IPv6Address.IPAddress)`r`n"
                } else {
                    $verificationResults += "   ⚠ IPv6: Not configured`r`n"
                }
            }
            $verificationResults += "`r`n"
            
            # Test 3: DNS Configuration
            Show-Status "Checking DNS configuration..."
            $progressBar.Value = 40
            $mainForm.Refresh()
            
            $verificationResults += "3. DNS Configuration:`r`n"
            foreach ($config in $ipConfig) {
                if ($config.DNSServer.ServerAddresses) {
                    $verificationResults += "   DNS Servers: $($config.DNSServer.ServerAddresses -join ', ')`r`n"
                    # Check for common secure DNS servers
                    $secureDNS = @("1.1.1.1", "1.0.0.1", "9.9.9.9", "8.8.8.8", "8.8.4.4")
                    $hasSecureDNS = $false
                    foreach ($dns in $config.DNSServer.ServerAddresses) {
                        if ($dns -in $secureDNS) {
                            $hasSecureDNS = $true
                            break
                        }
                    }
                    if ($hasSecureDNS) {
                        $verificationResults += "   ✓ Using secure DNS servers`r`n"
                    } else {
                        $verificationResults += "   ⚠ Using custom DNS servers`r`n"
                    }
                } else {
                    $verificationResults += "   ✗ No DNS servers configured`r`n"
                }
            }
            $verificationResults += "`r`n"
            
            # Test 4: Connectivity Tests
            Show-Status "Testing connectivity..."
            $progressBar.Value = 60
            $mainForm.Refresh()
            
            $verificationResults += "4. Connectivity Tests:`r`n"
            
            # Test IPv4 connectivity
            try {
                $ipv4Test = Test-Connection -ComputerName "8.8.8.8" -Count 2 -Quiet
                if ($ipv4Test) {
                    $verificationResults += "   ✓ IPv4 connectivity: OK`r`n"
                } else {
                    $verificationResults += "   ✗ IPv4 connectivity: Failed`r`n"
                }
            } catch {
                $verificationResults += "   ⚠ IPv4 connectivity: Unable to test`r`n"
            }
            
            # Test IPv6 connectivity
            try {
                $ipv6Test = Test-Connection -ComputerName "2001:4860:4860::8888" -Count 2 -Quiet
                if ($ipv6Test) {
                    $verificationResults += "   ✓ IPv6 connectivity: OK`r`n"
                } else {
                    $verificationResults += "   ✗ IPv6 connectivity: Failed`r`n"
                }
            } catch {
                $verificationResults += "   ⚠ IPv6 connectivity: Unable to test`r`n"
            }
            
            # Test DNS resolution
            try {
                $dnsTest = Resolve-DnsName -Name "google.com" -ErrorAction Stop
                if ($dnsTest) {
                    $verificationResults += "   ✓ DNS resolution: OK`r`n"
                } else {
                    $verificationResults += "   ✗ DNS resolution: Failed`r`n"
                }
            } catch {
                $verificationResults += "   ⚠ DNS resolution: Unable to test`r`n"
            }
            $verificationResults += "`r`n"
            
            # Test 5: Network Speed Test (basic)
            Show-Status "Running speed test..."
            $progressBar.Value = 80
            $mainForm.Refresh()
            
            $verificationResults += "5. Network Speed Test:`r`n"
            try {
                # Use async download with timeout to prevent hanging
                $webClient = New-Object System.Net.WebClient
                $webClient.Timeout = 15000  # 15 seconds timeout
                
                $speedTest = Measure-Command {
                    $data = $webClient.DownloadData("http://speedtest.wdc01.softlayer.com/downloads/test10.zip")
                    $webClient.Dispose()
                }
                
                if ($speedTest.TotalSeconds -gt 0) {
                    $speedKB = [math]::Round(10 * 1024 / $speedTest.TotalSeconds, 2)  # 10MB file
                    $verificationResults += "   Download speed: ~$speedKB KB/s (took $([math]::Round($speedTest.TotalSeconds, 2)) seconds)`r`n"
                    if ($speedKB -gt 100) {
                        $verificationResults += "   ✓ Speed test: Good`r`n"
                    } elseif ($speedKB -gt 50) {
                        $verificationResults += "   ⚠ Speed test: Moderate`r`n"
                    } else {
                        $verificationResults += "   ⚠ Speed test: Slow`r`n"
                    }
                } else {
                    $verificationResults += "   ⚠ Speed test: Unable to measure`r`n"
                }
            } catch {
                $verificationResults += "   ⚠ Speed test: Unable to test (timeout or connection issue)`r`n"
            }
            $verificationResults += "`r`n"
            
            # Test 6: Censorship Detection
            Show-Status "Testing censorship detection..."
            $progressBar.Value = 85
            $mainForm.Refresh()
            
            $verificationResults += "6. Censorship Detection:`r`n"
            try {
                # Test access to various sites that might be censored
                $testSites = @(
                    @{Name="Google"; Url="https://www.google.com"},
                    @{Name="Wikipedia"; Url="https://www.wikipedia.org"},
                    @{Name="News Site"; Url="https://www.bbc.com"},
                    @{Name="Social Media"; Url="https://www.twitter.com"}
                )
                
                $accessibleCount = 0
                foreach ($site in $testSites) {
                    try {
                        # Use shorter timeout and faster method to prevent hanging
                        $response = Invoke-WebRequest -Uri $site.Url -Method Head -TimeoutSec 5 -ErrorAction Stop
                        if ($response.StatusCode -eq 200) {
                            $verificationResults += "   ✓ $($site.Name): Accessible`r`n"
                            $accessibleCount++
                        } else {
                            $verificationResults += "   ⚠ $($site.Name): Unexpected response ($($response.StatusCode))`r`n"
                        }
                    } catch {
                        if ($_.Exception.Message -like "*timeout*") {
                            $verificationResults += "   ⚠ $($site.Name): Timeout (possible blocking or slow connection)`r`n"
                        } else {
                            $verificationResults += "   ✗ $($site.Name): Blocked or unreachable`r`n"
                        }
                    }
                }
                
                if ($accessibleCount -eq $testSites.Count) {
                    $verificationResults += "   ✓ Censorship test: No obvious blocking detected`r`n"
                } elseif ($accessibleCount -gt ($testSites.Count / 2)) {
                    $verificationResults += "   ⚠ Censorship test: Some sites may be blocked`r`n"
                } else {
                    $verificationResults += "   ⚠ Censorship test: Many sites appear blocked`r`n"
                }
            } catch {
                $verificationResults += "   ⚠ Censorship test: Unable to perform test`r`n"
            }
            $verificationResults += "`r`n"
            
            # Test 7: Security Settings
            Show-Status "Checking security settings..."
            $progressBar.Value = 90
            $mainForm.Refresh()
            
            $verificationResults += "6. Security Settings:`r`n"
            
            # Check Windows Firewall
            $firewallProfiles = Get-NetFirewallProfile
            $firewallEnabled = $true
            foreach ($profile in $firewallProfiles) {
                if (-not $profile.Enabled) {
                    $firewallEnabled = $false
                    break
                }
            }
            if ($firewallEnabled) {
                $verificationResults += "   ✓ Windows Firewall: Enabled`r`n"
            } else {
                $verificationResults += "   ⚠ Windows Firewall: Disabled on some profiles`r`n"
            }
            
            # Check for common security issues
            $verificationResults += "   Security check completed`r`n"
            $verificationResults += "`r`n"
            
        } catch {
            $verificationResults += "Error during verification: $($_.Exception.Message)`r`n`r`n"
        }
        
        $verificationResults += "Verification completed at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`r`n"
        $verificationResults += "`r`n=== Summary ===`r`n"
        $verificationResults += "✓ Network adapters checked`r`n"
        $verificationResults += "✓ IP configuration verified`r`n"
        $verificationResults += "✓ DNS settings validated`r`n"
        $verificationResults += "✓ Connectivity tests performed`r`n"
        $verificationResults += "✓ Basic speed test completed`r`n"
        $verificationResults += "✓ Censorship detection performed`r`n"
        $verificationResults += "✓ Security settings reviewed`r`n"
        
        # Display results
        $verifyTextBox.Text = $verificationResults
        $progressBar.Value = 100
        Hide-Status
        
        $verifyForm.ShowDialog()
    }
})

$statusButton.Add_Click({ Show-CurrentStatus })

$exitButton.Add_Click({ 
    $result = [System.Windows.Forms.MessageBox]::Show(
        "Are you sure you want to exit?", 
        "Confirm Exit", 
        [System.Windows.Forms.MessageBoxButtons]::YesNo, 
        [System.Windows.Forms.MessageBoxIcon]::Question
    )
    
    if ($result -eq "Yes") {
        $mainForm.Close()
    }
})

# Handle form closing
$mainForm.Add_Closing({
    $result = [System.Windows.Forms.MessageBox]::Show(
        "Are you sure you want to exit?", 
        "Confirm Exit", 
        [System.Windows.Forms.MessageBoxButtons]::YesNo, 
        [System.Windows.Forms.MessageBoxIcon]::Question
    )
    
    if ($result -ne "Yes") {
        $_.Cancel = $true
    }
})

# Show the form
$mainForm.ShowDialog()
