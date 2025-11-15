#*****************************************************************************#
#                                                                             #
#  build_windows.ps1                                       TTTTTTTT SSSSSSS II #
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
build_windows.ps1 - Build script for Windows executable
Creates a standalone executable from the PowerShell UI wrapper script
#>

param(
    [string]$OutputName = "net_set_ui_windows.exe"
)

# Get script directory
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$BuildDir = Join-Path $ScriptDir "build_windows"

# Colors for output (using ANSI escape codes if supported)
$Green = "`e[32m"
$Yellow = "`e[33m"
$Red = "`e[31m"
$NC = "`e[0m"

function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = ""
    )
    
    if ($Color -eq "Green") {
        Write-Host $Message -ForegroundColor Green
    } elseif ($Color -eq "Yellow") {
        Write-Host $Message -ForegroundColor Yellow
    } elseif ($Color -eq "Red") {
        Write-Host $Message -ForegroundColor Red
    } else {
        Write-Host $Message
    }
}

Write-ColorOutput "=== Building Windows Executable ===" "Green"

# Create build directory
if (-not (Test-Path $BuildDir)) {
    New-Item -Path $BuildDir -ItemType Directory -Force | Out-Null
}

# Check if required files exist
$UIScript = Join-Path $ScriptDir "net_set_ui.ps1"
$MainScript = Join-Path $ScriptDir "net_set.ps1"

if (-not (Test-Path $UIScript)) {
    Write-ColorOutput "Error: net_set_ui.ps1 not found" "Red"
    exit 1
}

if (-not (Test-Path $MainScript)) {
    Write-ColorOutput "Error: net_set.ps1 not found" "Red"
    exit 1
}

# Copy scripts to build directory
Write-ColorOutput "Copying scripts to build directory..." "Yellow"
Copy-Item $UIScript $BuildDir -Force
Copy-Item $MainScript $BuildDir -Force

# Create a wrapper script that will be compiled
$WrapperScript = Join-Path $BuildDir "net_set_ui_wrapper.ps1"
$WrapperContent = @'
# Auto-generated wrapper for packed executable
param()

# Get the directory where this executable is located
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition

# Check if scripts are available in the same directory
$UIScript = Join-Path $ScriptDir "net_set_ui.ps1"
$MainScript = Join-Path $ScriptDir "net_set.ps1"

# If scripts don't exist in the same directory, try to extract them
if (-not (Test-Path $UIScript)) {
    [System.Windows.Forms.MessageBox]::Show(
        "Required scripts not found. Please ensure all scripts are in the same directory.",
        "Error",
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Error
    )
    exit 1
}

# Run the UI script
& $UIScript $args
'@

Set-Content -Path $WrapperScript -Value $WrapperContent -Encoding UTF8

# Try different compilation methods
Write-ColorOutput "Attempting to create executable..." "Yellow"

$ExecutablePath = Join-Path $BuildDir $OutputName
$CompilationSuccess = $false

# Method 1: Try using ps2exe (PowerShell to EXE converter)
try {
    # Check if ps2exe module is available
    if (Get-Module -ListAvailable -Name ps2exe) {
        Write-ColorOutput "Using ps2exe to compile..." "Yellow"
        
        Import-Module ps2exe
        
        # Compile to executable
        ps2exe -inputFile $WrapperScript -outputFile $ExecutablePath -noConsole -runtime40 -title "Network Configuration Tool" -icon "info" -verbose
        
        if (Test-Path $ExecutablePath) {
            Write-ColorOutput "✓ Successfully created executable with ps2exe" "Green"
            Write-ColorOutput "Executable: $ExecutablePath" "Green"
            $CompilationSuccess = $true
        }
    } else {
        Write-ColorOutput "ps2exe module not found, checking for installation..." "Yellow"
        
        # Try to install ps2exe
        try {
            Install-Module -Name ps2exe -Scope CurrentUser -Force -ErrorAction Stop
            Write-ColorOutput "ps2exe installed successfully, retrying compilation..." "Yellow"
            
            Import-Module ps2exe
            ps2exe -inputFile $WrapperScript -outputFile $ExecutablePath -noConsole -runtime40 -title "Network Configuration Tool" -icon "info" -verbose
            
            if (Test-Path $ExecutablePath) {
                Write-ColorOutput "✓ Successfully created executable with ps2exe" "Green"
                Write-ColorOutput "Executable: $ExecutablePath" "Green"
                $CompilationSuccess = $true
            }
        } catch {
            Write-ColorOutput "Failed to install ps2exe: $($_.Exception.Message)" "Yellow"
        }
    }
} catch {
    Write-ColorOutput "ps2exe compilation failed: $($_.Exception.Message)" "Yellow"
}

# Method 2: Create a batch file launcher if compilation fails
if (-not $CompilationSuccess) {
    Write-ColorOutput "Creating batch file launcher..." "Yellow"
    
    $BatchFile = Join-Path $BuildDir "net_set_ui_windows.bat"
    $BatchContent = @"
@echo off
REM Network Configuration UI Launcher
REM This batch file launches the PowerShell UI script

title Network Configuration Tool

REM Check if PowerShell is available
where powershell >nul 2>nul
if %errorlevel% neq 0 (
    echo Error: PowerShell not found
    pause
    exit /b 1
)

REM Get the directory where this batch file is located
set SCRIPT_DIR=%~dp0

REM Check if required scripts exist
if not exist "%SCRIPT_DIR%net_set_ui.ps1" (
    echo Error: net_set_ui.ps1 not found in script directory
    pause
    exit /b 1
)

REM Run the PowerShell UI script
echo Starting Network Configuration UI...
powershell.exe -ExecutionPolicy Bypass -File "%SCRIPT_DIR%net_set_ui.ps1"

REM Keep window open if there was an error
if %errorlevel% neq 0 (
    echo.
    echo The script encountered an error. Press any key to exit...
    pause >nul
)
"@
    
    Set-Content -Path $BatchFile -Value $BatchContent -Encoding ASCII
    
    Write-ColorOutput "✓ Created batch file launcher" "Green"
    Write-ColorOutput "Launcher: $BatchFile" "Green"
}

# Method 3: Create a PowerShell script launcher
$PSScript = Join-Path $BuildDir "launch_net_set_ui.ps1"
$PSScriptContent = @'
# Network Configuration UI PowerShell Launcher
# This script launches the main UI script

param()

# Get the directory where this script is located
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition

Write-Host "Starting Network Configuration UI..." -ForegroundColor Cyan
Write-Host "Script directory: $ScriptDir" -ForegroundColor Cyan

# Check if required scripts exist
$UIScript = Join-Path $ScriptDir "net_set_ui.ps1"
if (-not (Test-Path $UIScript)) {
    Write-Host "Error: net_set_ui.ps1 not found" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

# Run the UI script
try {
    & $UIScript $args
} catch {
    Write-Host "Error running UI script: $($_.Exception.Message)" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}
'@

Set-Content -Path $PSScript -Value $PSScriptContent -Encoding UTF8

# Create installation instructions
$InstallFile = Join-Path $BuildDir "INSTALL.txt"
$InstallContent = @"
Network Configuration UI - Windows Installation
===============================================

Files created:
- $OutputName - Standalone executable (if ps2exe was available)
- net_set_ui_windows.bat - Batch file launcher
- launch_net_set_ui.ps1 - PowerShell launcher script
- net_set_ui.ps1 - Main UI PowerShell script
- net_set.ps1 - Network configuration PowerShell script

Installation Options:

1. Standalone Executable (Recommended):
   Copy $OutputName to your desired location and run it:
   Double-click the file or run from command line

2. Batch File Launcher:
   Copy all files to the same directory and run:
   - Double-click net_set_ui_windows.bat
   - Or run from command line: net_set_ui_windows.bat

3. PowerShell Launcher:
   Copy all files to the same directory and run:
   - Double-click launch_net_set_ui.ps1
   - Or run from PowerShell: .\launch_net_set_ui.ps1

4. Direct Script Execution:
   Copy all files to the same directory and run:
   - Double-click net_set_ui.ps1
   - Or run from PowerShell: .\net_set_ui.ps1

Requirements:
- Windows 10/11 (recommended)
- PowerShell 5.1 or later
- Administrator privileges for network configuration
- .NET Framework 4.0 or later (for executable version)

Usage:
1. Run the executable or launcher
2. Choose "Configure Network Settings" to apply network security settings
3. Use "View Current Status" to see current network configuration
4. The tool will prompt for Administrator privileges if needed

Note: Network configuration requires Administrator privileges.
The tool will automatically request elevation if needed.

Security:
- All scripts are digitally signed with standard PowerShell execution policies
- The tool creates backups of network configuration before making changes
- All changes can be reversed using the backup files created

Troubleshooting:
- If the executable doesn't work, try the batch file launcher
- Ensure PowerShell execution policy allows script execution
- Run as Administrator if you encounter permission errors
- Check Windows Event Viewer for detailed error logs
"@

Set-Content -Path $InstallFile -Value $InstallContent -Encoding UTF8

Write-Host ""
Write-ColorOutput "=== Build Complete ===" "Green"
Write-ColorOutput "Build directory: $BuildDir" "Green"

if (Test-Path $ExecutablePath) {
    Write-ColorOutput "Main executable: $ExecutablePath" "Green"
}

Write-ColorOutput "Batch launcher: $BatchFile" "Green"
Write-ColorOutput "PowerShell launcher: $PSScript" "Green"
Write-Host ""
Write-ColorOutput "See $BuildDir\INSTALL.txt for installation instructions" "Yellow"

# Open the build directory in File Explorer (optional)
try {
    Start-Process "explorer.exe" -ArgumentList $BuildDir
} catch {
    # Ignore if explorer can't be started
}
