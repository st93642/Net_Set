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
        (
            echo "10"
            echo "# Checking network status..."
            sleep 1
            
            echo "50"
            echo "# Running verification tests..."
            sleep 2
            
            if sudo "$VERIFY_SCRIPT" 2>&1 | while read -r line; do
                echo "# $line"
                echo "75"
                sleep 0.3
            done; then
                echo "100"
                echo "# Verification completed!"
            else
                echo "# Verification completed with warnings!"
            fi
        ) | show_progress_gui "Verifying network configuration..."
        
        show_info "Network verification completed!"
    else
        show_info "Starting network verification..."
        sudo "$VERIFY_SCRIPT"
        show_info "Network verification completed!"
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
