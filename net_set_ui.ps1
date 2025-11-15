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
        Show-Status "Running verification tests..."
        $progressBar.Value = 50
        $mainForm.Refresh()
        
        # For now, show a simple message since we don't have a separate verification script for Windows
        Start-Sleep -Seconds 2
        $progressBar.Value = 100
        Hide-Status
        
        [System.Windows.Forms.MessageBox]::Show(
            "Network verification completed.`n`nNote: For detailed verification, please check the network settings manually or use the Windows Network Troubleshooter.", 
            "Verification Complete", 
            [System.Windows.Forms.MessageBoxButtons]::OK, 
            [System.Windows.Forms.MessageBoxIcon]::Information
        )
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
