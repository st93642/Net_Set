#!/bin/bash

#*****************************************************************************#
#                                                                             #
#  net_set_ui.sh                                            TTTTTTTT SSSSSSS II #
#                                                            TT    SS      II #
#  By: st93642@students.tsi.lv                               TT    SSSSSSS II #
#                                                            TT         SS II #
#  Created: Nov 15 2025 09:21 st93642                       TT    SSSSSSS II #
#  Updated: Nov 15 2025 09:21 st93642                                         #
#                                                                             #
#   Transport and Telecommunication Institute - Riga, Latvia                  #
#                       https://tsi.lv                                        #
#*****************************************************************************#

# Desktop UI wrapper for net_set.sh Linux version
# Provides graphical interface using zenity with terminal fallback

set -e

# Colors for terminal mode
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# Determine if we're in GUI mode or terminal mode
GUI_MODE=false
if command -v zenity >/dev/null 2>&1 && [ -n "$DISPLAY" ]; then
    GUI_MODE=true
fi

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NET_SET_SCRIPT="$SCRIPT_DIR/net_set.sh"
VERIFY_SCRIPT="$SCRIPT_DIR/network-verify.sh"

# Check if main scripts exist
if [ ! -f "$NET_SET_SCRIPT" ]; then
    if [ "$GUI_MODE" = true ]; then
        zenity --error --text="Error: net_set.sh not found in script directory" --title="Network Configuration"
    else
        echo -e "${RED}Error: net_set.sh not found in script directory${NC}"
    fi
    exit 1
fi

# GUI functions
show_info_gui() {
    zenity --info --text="$1" --title="Network Configuration" --width=400
}

show_error_gui() {
    zenity --error --text="$1" --title="Network Configuration Error" --width=400
}

show_question_gui() {
    zenity --question --text="$1" --title="Network Configuration" --width=400 --height=200
}

show_progress_gui() {
    zenity --progress --title="Network Configuration" --text="$1" --width=400 --height=200 --auto-close
}

show_main_menu_gui() {
    choice=$(zenity --list --title="Network Configuration Tool" --text="Select an action:" --column="Action" \
        "Configure Network Settings" \
        "Verify Network Configuration" \
        "View Current Status" \
        "Exit" \
        --width=400 --height=300)
    echo "$choice"
}

# Terminal functions
show_info_term() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

show_error_term() {
    echo -e "${RED}[ERROR]${NC} $1"
}

show_question_term() {
    echo -e "${YELLOW}[QUESTION]${NC} $1"
    read -p "Continue? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        return 1
    fi
    return 0
}

show_main_menu_term() {
    echo -e "${BLUE}=== Network Configuration Tool ===${NC}"
    echo "1) Configure Network Settings"
    echo "2) Verify Network Configuration"
    echo "3) View Current Status"
    echo "4) Exit"
    echo
    read -p "Select an option (1-4): " choice
    case $choice in
        1) echo "Configure Network Settings" ;;
        2) echo "Verify Network Configuration" ;;
        3) echo "View Current Status" ;;
        4) echo "Exit" ;;
        *) echo "Exit" ;;
    esac
}

# Unified functions
show_info() {
    if [ "$GUI_MODE" = true ]; then
        show_info_gui "$1"
    else
        show_info_term "$1"
    fi
}

show_error() {
    if [ "$GUI_MODE" = true ]; then
        show_error_gui "$1"
    else
        show_error_term "$1"
    fi
}

show_question() {
    if [ "$GUI_MODE" = true ]; then
        show_question_gui "$1"
    else
        show_question_term "$1"
    fi
}

show_main_menu() {
    if [ "$GUI_MODE" = true ]; then
        show_main_menu_gui
    else
        show_main_menu_term
    fi
}

# Run configuration with progress tracking
run_configuration() {
    if [ "$GUI_MODE" = true ]; then
        (
            echo "10"
            echo "# Checking permissions..."
            sleep 1
            
            echo "20"
            echo "# Preparing system configuration..."
            sleep 1
            
            # Run the actual script in background and capture output
            if sudo "$NET_SET_SCRIPT" 2>&1 | while read -r line; do
                echo "# $line"
                echo "30"
                sleep 0.5
            done; then
                echo "100"
                echo "# Configuration completed successfully!"
            else
                echo "# Configuration failed!"
                exit 1
            fi
        ) | show_progress_gui "Configuring network settings..."
        
        if [ $? -eq 0 ]; then
            show_info "Network configuration completed successfully!"
        else
            show_error "Network configuration failed. Please check the logs."
        fi
    else
        show_info "Starting network configuration..."
        if sudo "$NET_SET_SCRIPT"; then
            show_info "Network configuration completed successfully!"
        else
            show_error "Network configuration failed. Please check the error messages above."
            return 1
        fi
    fi
}

# Run verification
run_verification() {
    if [ "$GUI_MODE" = true ]; then
        # Create temporary file to store verification results
        tmpfile=$(mktemp)
        
        (
            echo "5"
            echo "# Initializing verification..."
            sleep 1
            
            echo "15"
            echo "# Checking IPv6 status..."
            sleep 1
            
            echo "25"
            echo "# Verifying DNS configuration..."
            sleep 1
            
            echo "35"
            echo "# Testing DNS over HTTPS..."
            sleep 1
            
            echo "45"
            echo "# Checking public IP addresses..."
            sleep 1
            
            echo "55"
            echo "# Analyzing local interfaces..."
            sleep 1
            
            echo "65"
            echo "# Running connectivity tests..."
            sleep 1
            
            echo "75"
            echo "# Testing censorship detection..."
            sleep 1
            
            echo "85"
            echo "# Measuring network speed..."
            echo "# (This may take a moment - testing with optimized timeouts)"
            sleep 1
            
            echo "90"
            echo "# Running final tests..."
            sleep 1
            
            echo "95"
            echo "# Generating comprehensive report..."
            
            # Run verification with timeout and progress tracking
                        # Use timeout to prevent hanging on slow operations
                        # Simplified approach - try to run verification with fallbacks
                        echo "# Running verification script..."

                        # First try: Run without sudo to see what we can do
                        if "$VERIFY_SCRIPT" > "$tmpfile" 2>&1; then
                            echo "100"
                            echo "# Verification completed (limited privileges)!"
                        else
                            # Second try: Try with sudo if we have it available
                            if [ "$EUID" -ne 0 ] && sudo -n true 2>/dev/null; then
                                echo "# Attempting with elevated privileges..."
                                if timeout 120 sudo -n "$VERIFY_SCRIPT" >> "$tmpfile" 2>&1; then
                                    echo "100"
                                        echo "# Verification completed successfully!"
                                else
                                    echo "100"
                                        echo "# Verification completed with warnings (some tests may have failed)"
                                fi
                            else
                                # Third try: Try with interactive sudo as last resort
                                echo "# Requires administrator privileges..."
                                if timeout 120 sudo "$VERIFY_SCRIPT" >> "$tmpfile" 2>&1; then
                                    echo "100"
                                        echo "# Verification completed successfully!"
                                else
                                    echo "100"
                                        echo "# Verification completed - some tests may have failed"
                                fi
                            fi
                        fi
        ) | show_progress_gui "Verifying network configuration..."
        
        # Display results in a text window
        if [ -s "$tmpfile" ]; then
            # Debug: Show file size and first few lines
            file_size=$(wc -c < "$tmpfile" | awk '{print $1}')
            echo "DEBUG: Verification output file size: $file_size bytes" >&2
            echo "DEBUG: First 200 chars:" >&2
            head -c 200 "$tmpfile" >&2
            
            # Clean ANSI color codes and format output for GUI display
            clean_output=$(sed 's/\x1b\[[0-9;]*[a-zA-Z]//g' "$tmpfile" | \
                         sed 's/\x1b\[[0-9]*[a-zA-Z]//g' | \
                         sed 's/\[0;34m\]/[INFO]/g' | \
                         sed 's/\[0;32m\]/[SUCCESS]/g' | \
                         sed 's/\[1;33m\]/[WARNING]/g' | \
                         sed 's/\[0;31m\]/[ERROR]/g' | \
                         sed 's/\[0m\]//g' | \
                         sed 's/\[NC\]//g' | \
                         sed 's/^\[INFO\]/[INFO]/g' | \
                         sed 's/^\[SUCCESS\]/[SUCCESS]/g' | \
                         sed 's/^\[WARNING\]/[WARNING]/g' | \
                         sed 's/^\[ERROR\]/[ERROR]/g' | \
                         sed 's/===/===/g' | \
                         sed 's/---/---/g' | \
                         sed 's/Interface:/Interface:/g')
            
            # Check if cleaning worked and we have content
            if [ -n "$clean_output" ]; then
                # Create a formatted results display with summary at top
                results_summary="=== Network Verification Summary ===\n\n"
                results_summary+="This verification checked:\n"
                results_summary+="[+] IPv6 connectivity and configuration\n"
                results_summary+="[+] DNS settings and DNS over HTTPS (DoH)\n"
                results_summary+="[+] Public IP address detection (IPv4/IPv6)\n"
                results_summary+="[+] Local network interface analysis\n"
                results_summary+="[+] Network connectivity tests\n"
                results_summary+="[+] Censorship detection tests\n"
                results_summary+="[+] Network speed measurements\n"
                results_summary+="[+] Security settings validation\n\n"
                results_summary+="=== Detailed Results ===\n\n"
                results_summary+="$clean_output"
                
                # Use zenity to show the results in a scrollable text window
                echo -e "$results_summary" | zenity --text-info \
                    --title="Network Verification Results" \
                    --width=900 \
                    --height=700 \
                    --filename=/dev/stdin 2>/dev/null || {
                    # Fallback to info dialog if text-info fails
                    show_info "Network verification completed! Detailed results saved to temporary file."
                }
            else
                # Try to show raw output if cleaning failed
                echo "DEBUG: Clean output was empty, showing raw output" >&2
                echo -e "$tmpfile" | zenity --text-info \
                    --title="Network Verification Results (Raw)" \
                    --width=900 \
                    --height=700 \
                    --filename=/dev/stdin 2>/dev/null || {
                    show_error "Verification completed but results display failed."
                }
            fi
        else
            show_error "No verification results available. Please check the script output."
            echo "DEBUG: Temporary file is empty or missing" >&2
        fi
        
        # Clean up - but preserve for debugging if needed
        if [ "$DEBUG_MODE" = "true" ]; then
            echo "DEBUG: Preserving verification output to /tmp/net_set_debug.log"
            cp "$tmpfile" "/tmp/net_set_debug.log" 2>/dev/null
        fi
        rm -f "$tmpfile"
    else
        show_info "Starting network verification..."
        echo
        echo -e "${BLUE}=== Network Verification ===${NC}"
        echo "This verification will check:"
        echo "  [+] IPv6 connectivity and configuration"
        echo "  [+] DNS settings and DNS over HTTPS (DoH)"
        echo "  [+] Public IP address detection (IPv4/IPv6)"
        echo "  [+] Local network interface analysis"
        echo "  [+] Network connectivity tests"
        echo "  [+] Censorship detection tests"
        echo "  [+] Network speed measurements"
        echo "  [+] Security settings validation"
        echo
        
        # Check if we need sudo
        if [ "$EUID" -eq 0 ]; then
            echo -e "${GREEN}Running as root - no password required${NC}"
            sudo "$VERIFY_SCRIPT"
        else
            echo -e "${YELLOW}Administrator privileges required for full verification${NC}"
            echo "Attempting to run verification with sudo..."
            if sudo -n true 2>/dev/null; then
                echo -e "${GREEN}Using non-interactive sudo${NC}"
                sudo -n "$VERIFY_SCRIPT"
            else
                echo -e "${RED}Interactive sudo required${NC}"
                echo "Please run the following command manually:"
                echo -e "${BLUE}sudo $VERIFY_SCRIPT${NC}"
                echo ""
                echo -e "${YELLOW}Or run this UI with sudo: sudo ./net_set_ui.sh${NC}"
                exit 1
            fi
        fi
        
        echo
        echo -e "${GREEN}=== Verification Summary ===${NC}"
        echo "[+] Network verification completed!"
        echo "[+] Results shown above include:"
        echo "  - IPv6 connectivity status"
        echo "  - DNS configuration verification"
        echo "  - DNS over HTTPS (DoH) status"
        echo "  - Public IP addresses (IPv4/IPv6)"
        echo "  - Local interface information"
        echo "  - Network connectivity tests"
        echo "  - Censorship detection results"
        echo "  - Network speed measurements"
        echo "  - Security settings validation"
        echo
    fi
}

# Show current status
show_status() {
    if [ "$GUI_MODE" = true ]; then
        status_text="Current Network Status:\n\n"
        
        # Get IPv6 status
        if ip -6 addr show | grep -q "inet6"; then
            status_text+="IPv6: Enabled\n"
        else
            status_text+="IPv6: Disabled\n"
        fi
        
        # Get DNS info
        if command -v resolvectl >/dev/null 2>&1; then
            dns_server=$(resolvectl status 2>/dev/null | grep 'Current DNS Server' | awk '{print $4}' || echo "Unknown")
            status_text+="DNS Server: $dns_server\n"
        fi
        
        # Check systemd-resolved status
        if systemctl is-active --quiet systemd-resolved; then
            status_text+="systemd-resolved: Active\n"
        else
            status_text+="systemd-resolved: Inactive\n"
        fi
        
        zenity --info --text="$status_text" --title="Network Status" --width=400
    else
        echo -e "${BLUE}=== Current Network Status ===${NC}"
        echo
        
        echo -e "${YELLOW}IPv6 Status:${NC}"
        ip -6 addr show | grep inet6 | head -3
        echo
        
        echo -e "${YELLOW}DNS Configuration:${NC}"
        if [ -f /etc/resolv.conf ]; then
            grep -E "^nameserver|^options" /etc/resolv.conf | head -3
        fi
        echo
        
        echo -e "${YELLOW}systemd-resolved Status:${NC}"
        systemctl status systemd-resolved --no-pager -l | head -3
        echo
    fi
}

# Main loop
main() {
    # Check if running as root for configuration
    if [ "$EUID" -ne 0 ]; then
        show_info "This tool may require administrative privileges for network configuration."
        show_info "You will be prompted for password when needed."
    fi
    
    while true; do
        choice=$(show_main_menu)
        
        case "$choice" in
            "Configure Network Settings")
                if show_question "This will configure IPv6, DNS over TLS, and apply network security settings.\n\nDo you want to continue?"; then
                    run_configuration
                fi
                ;;
            "Verify Network Configuration")
                if show_question "This will run comprehensive network verification tests.\n\nDo you want to continue?"; then
                    run_verification
                fi
                ;;
            "View Current Status")
                show_status
                ;;
            "Exit"|"4")
                show_info "Goodbye!"
                exit 0
                ;;
            *)
                if [ "$GUI_MODE" = false ]; then
                    echo "Invalid option. Please try again."
                fi
                ;;
        esac
        
        if [ "$GUI_MODE" = true ]; then
            # Small delay in GUI mode to prevent immediate re-showing
            sleep 0.5
        else
            echo
            read -p "Press Enter to continue..."
            echo
        fi
    done
}

# Start the application
main
