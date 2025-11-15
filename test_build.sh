#!/bin/bash

# Simple test build script
echo "=== Testing Build Process ==="

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$SCRIPT_DIR/build_linux"

echo "Script directory: $SCRIPT_DIR"
echo "Build directory: $BUILD_DIR"

# Create build directory
mkdir -p "$BUILD_DIR"

# Copy files
echo "Copying files..."
cp "$SCRIPT_DIR/net_set_ui.sh" "$BUILD_DIR/"
cp "$SCRIPT_DIR/net_set.sh" "$BUILD_DIR/"
cp "$SCRIPT_DIR/network-verify.sh" "$BUILD_DIR/"

echo "Files copied successfully"
echo "Build directory contents:"
ls -la "$BUILD_DIR/"

# Create a simple launcher
LAUNCHER="$BUILD_DIR/launch_test.sh"
cat > "$LAUNCHER" << 'EOF'
#!/bin/bash
echo "Test launcher - UI would start here"
echo "Script directory: $(pwd)"
ls -la
EOF

chmod +x "$LAUNCHER"

echo "Test build completed successfully"
echo "Created test launcher: $LAUNCHER"
