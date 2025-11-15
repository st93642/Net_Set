#!/bin/bash

#*****************************************************************************#
#                                                                             #
#  build_linux.sh                                          TTTTTTTT SSSSSSS II #
#                                                            TT    SS      II #
#  By: st93642@students.tsi.lv                               TT    SSSSSSS II #
#                                                            TT         SS II #
#  Created: Nov 15 2025 09:21 st93642                       TT    SSSSSSS II #
#  Updated: Nov 15 2025 09:21 st93642                                         #
#                                                                             #
#   Transport and Telecommunication Institute - Riga, Latvia                  #
#                       https://tsi.lv                                        #
#*****************************************************************************#

# Build script for Linux executable
# Creates a standalone executable from the UI wrapper script

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$SCRIPT_DIR/build_linux"
OUTPUT_NAME="net_set_ui_linux"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}=== Building Linux Executable ===${NC}"

# Create build directory
mkdir -p "$BUILD_DIR"

# Check if required files exist
UI_SCRIPT="$SCRIPT_DIR/net_set_ui.sh"
MAIN_SCRIPT="$SCRIPT_DIR/net_set.sh"
VERIFY_SCRIPT="$SCRIPT_DIR/network-verify.sh"

if [ ! -f "$UI_SCRIPT" ]; then
    echo -e "${RED}Error: net_set_ui.sh not found${NC}"
    exit 1
fi

if [ ! -f "$MAIN_SCRIPT" ]; then
    echo -e "${RED}Error: net_set.sh not found${NC}"
    exit 1
fi

if [ ! -f "$VERIFY_SCRIPT" ]; then
    echo -e "${RED}Error: network-verify.sh not found${NC}"
    exit 1
fi

# Copy scripts to build directory
echo -e "${YELLOW}Copying scripts to build directory...${NC}"
cp "$UI_SCRIPT" "$BUILD_DIR/"
cp "$MAIN_SCRIPT" "$BUILD_DIR/"
cp "$VERIFY_SCRIPT" "$BUILD_DIR/"

# Create a wrapper script that will be compiled
WRAPPER_SCRIPT="$BUILD_DIR/net_set_ui_wrapper.sh"
cat > "$WRAPPER_SCRIPT" << 'EOF'
#!/bin/bash
# Auto-generated wrapper for packed executable

# Get the directory where this executable is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Check if scripts are available in the same directory
UI_SCRIPT="$SCRIPT_DIR/net_set_ui.sh"
MAIN_SCRIPT="$SCRIPT_DIR/net_set.sh"
VERIFY_SCRIPT="$SCRIPT_DIR/network-verify.sh"

# If scripts don't exist in the same directory, extract them from the executable
if [ ! -f "$UI_SCRIPT" ]; then
    # Extract embedded scripts (this will be handled by the packer)
    echo "Error: Required scripts not found. Please ensure all scripts are in the same directory."
    exit 1
fi

# Run the UI script
exec "$UI_SCRIPT" "$@"
EOF

chmod +x "$WRAPPER_SCRIPT"

# Try different compilation methods
echo -e "${YELLOW}Attempting to create executable...${NC}"

# Method 1: Try using shc (Shell Script Compiler)
if command -v shc >/dev/null 2>&1; then
    echo -e "${YELLOW}Using shc to compile...${NC}"
    cd "$BUILD_DIR"
    shc -f net_set_ui_wrapper.sh -o "$OUTPUT_NAME" -r
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Successfully created executable with shc${NC}"
        echo -e "${GREEN}Executable: $BUILD_DIR/$OUTPUT_NAME${NC}"
    else
        echo -e "${YELLOW}shc compilation failed, trying alternative method...${NC}"
    fi
else
    echo -e "${YELLOW}shc not found, trying alternative method...${NC}"
fi

# Method 2: Create a self-extracting archive
if [ ! -f "$BUILD_DIR/$OUTPUT_NAME" ] || [ ! -x "$BUILD_DIR/$OUTPUT_NAME" ]; then
    echo -e "${YELLOW}Creating self-extracting archive...${NC}"
    
    # Create a self-extracting script
    SELF_EXTRACT="$BUILD_DIR/$OUTPUT_NAME"
    cat > "$SELF_EXTRACT" << 'EOF2'
#!/bin/bash
# Self-extracting archive for net_set_ui

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMP_DIR="$SCRIPT_DIR/temp_net_set_$$"

# Create temporary directory
mkdir -p "$TEMP_DIR"

# Extract scripts (embedded after this line)
# The actual script content will be appended here by the build script
ARCHIVE_MARKER="__ARCHIVE_BELOW__"
LINE=$(awk "/^$ARCHIVE_MARKER$/ {print NR + 1; exit 0; }" "$0")
tail -n +$LINE "$0" | tar xz -C "$TEMP_DIR"

# Move scripts to the script directory
mv "$TEMP_DIR"/*.sh "$SCRIPT_DIR/" 2>/dev/null || true

# Clean up
rm -rf "$TEMP_DIR"

# Run the UI script
exec "$SCRIPT_DIR/net_set_ui.sh" "$@"

exit 0

__ARCHIVE_BELOW__
EOF2
    
    # Append the scripts as a tar archive
    cd "$BUILD_DIR"
    tar czf - net_set_ui.sh net_set.sh network-verify.sh >> "$OUTPUT_NAME"
    chmod +x "$OUTPUT_NAME"
    
    if [ -f "$OUTPUT_NAME" ] && [ -x "$OUTPUT_NAME" ]; then
        echo -e "${GREEN}✓ Successfully created self-extracting executable${NC}"
        echo -e "${GREEN}Executable: $BUILD_DIR/$OUTPUT_NAME${NC}"
    else
        echo -e "${RED}Failed to create executable${NC}"
        exit 1
    fi
fi

# Create a simple launcher script as fallback
LAUNCHER_SCRIPT="$BUILD_DIR/launch_net_set_ui.sh"
cat > "$LAUNCHER_SCRIPT" << EOF
#!/bin/bash
# Simple launcher for net_set_ui

SCRIPT_DIR="\$(cd "\$(dirname "\${BASH_SOURCE[0]}")" && pwd)"

echo "Starting Network Configuration UI..."
echo "Script directory: \$SCRIPT_DIR"

# Check if required scripts exist
if [ ! -f "\$SCRIPT_DIR/net_set_ui.sh" ]; then
    echo "Error: net_set_ui.sh not found"
    exit 1
fi

# Run the UI script
exec "\$SCRIPT_DIR/net_set_ui.sh" "\$@"
EOF

chmod +x "$LAUNCHER_SCRIPT"

# Create installation instructions
INSTALL_FILE="$BUILD_DIR/INSTALL.txt"
cat > "$INSTALL_FILE" << EOF
Network Configuration UI - Linux Installation
===============================================

Files created:
- $OUTPUT_NAME - Standalone executable (recommended)
- launch_net_set_ui.sh - Simple launcher script
- net_set_ui.sh - Main UI script
- net_set.sh - Network configuration script
- network-verify.sh - Network verification script

Installation Options:

1. Standalone Executable (Recommended):
   Copy $OUTPUT_NAME to your desired location and run it:
   ./$OUTPUT_NAME

2. Script-based Installation:
   Copy all .sh files to the same directory and run:
   ./launch_net_set_ui.sh
   or
   ./net_set_ui.sh

Requirements:
- Linux with systemd (for network configuration)
- sudo/root access for network changes
- zenity (for GUI mode, optional - will fallback to terminal)

GUI Mode:
- If zenity is installed and X11 is available, the tool will use GUI dialogs
- Otherwise, it will run in terminal mode

Usage:
1. Run the executable or launcher script
2. Choose "Configure Network Settings" to apply network security settings
3. Use "Verify Network Configuration" to test the setup
4. Use "View Current Status" to see current network configuration

Note: Network configuration requires administrative privileges.
EOF

echo
echo -e "${GREEN}=== Build Complete ===${NC}"
echo -e "${GREEN}Build directory: $BUILD_DIR${NC}"
echo -e "${GREEN}Main executable: $BUILD_DIR/$OUTPUT_NAME${NC}"
echo -e "${GREEN}Alternative launcher: $BUILD_DIR/launch_net_set_ui.sh${NC}"
echo
echo -e "${YELLOW}See $BUILD_DIR/INSTALL.txt for installation instructions${NC}"
