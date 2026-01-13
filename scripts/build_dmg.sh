#!/bin/bash
#
# WatchYourDay DMG Builder Script (Simplified)
# Usage: ./scripts/build_dmg.sh
#
# Creates a distributable DMG installer for WatchYourDay.
# Note: This version does NOT include code signing (Development builds only).
#

set -e  # Exit on any error

# Configuration
APP_NAME="WatchYourDay"
SCHEME="WatchYourDay"
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="$PROJECT_DIR/build"
DMG_PATH="$BUILD_DIR/$APP_NAME.dmg"

# Find DerivedData path for this project
DERIVED_DATA_BASE="$HOME/Library/Developer/Xcode/DerivedData"
DERIVED_DATA_PATH=$(find "$DERIVED_DATA_BASE" -maxdepth 1 -name "${APP_NAME}*" -type d 2>/dev/null | head -1)

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo_step() {
    echo -e "${GREEN}[STEP]${NC} $1"
}

echo_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

echo_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check dependencies
check_dependencies() {
    echo_step "Checking dependencies..."
    
    if ! command -v xcodebuild &> /dev/null; then
        echo_error "xcodebuild not found. Please install Xcode."
        exit 1
    fi
    
    echo "  ✓ xcodebuild found"
}

# Build the app
build_app() {
    echo_step "Building app (Release configuration)..."
    
    xcodebuild build \
        -project "$PROJECT_DIR/$APP_NAME.xcodeproj" \
        -scheme "$SCHEME" \
        -configuration Release \
        -destination 'platform=macOS,arch=arm64' \
        CODE_SIGN_IDENTITY="-" \
        CODE_SIGNING_REQUIRED=NO \
        CONFIGURATION_BUILD_DIR="$BUILD_DIR" \
        | grep -E "(Build|Compile|Link)" | tail -5 || true
    
    if [ ! -d "$BUILD_DIR/$APP_NAME.app" ]; then
        echo_error "Build failed. App not found at $BUILD_DIR/$APP_NAME.app"
        exit 1
    fi
    
    echo "  ✓ App built: $BUILD_DIR/$APP_NAME.app"
}

# Create DMG
create_dmg() {
    echo_step "Creating DMG installer..."
    
    # Remove old DMG if exists
    rm -f "$DMG_PATH"
    mkdir -p "$BUILD_DIR"
    
    # Create a temporary directory for DMG contents
    DMG_TEMP="$BUILD_DIR/dmg_temp"
    rm -rf "$DMG_TEMP"
    mkdir -p "$DMG_TEMP"
    
    # Copy app to temp dir
    cp -R "$BUILD_DIR/$APP_NAME.app" "$DMG_TEMP/"
    
    # Create Applications symlink for drag-to-install
    ln -s /Applications "$DMG_TEMP/Applications"
    
    # Use hdiutil for reliable DMG creation
    hdiutil create \
        -volname "$APP_NAME" \
        -srcfolder "$DMG_TEMP" \
        -ov \
        -format UDZO \
        "$DMG_PATH"
    
    # Cleanup temp
    rm -rf "$DMG_TEMP"
    
    if [ ! -f "$DMG_PATH" ]; then
        echo_error "DMG creation failed."
        exit 1
    fi
    
    # Get DMG size
    DMG_SIZE=$(du -h "$DMG_PATH" | cut -f1)
    echo "  ✓ DMG created: $DMG_PATH ($DMG_SIZE)"
}

# Print summary
print_summary() {
    echo ""
    echo "=========================================="
    echo -e "${GREEN}BUILD COMPLETE${NC}"
    echo "=========================================="
    echo "  App:     $BUILD_DIR/$APP_NAME.app"
    echo "  DMG:     $DMG_PATH"
    echo ""
    echo_warn "⚠️  This build is NOT signed or notarized."
    echo_warn "    Users may see Gatekeeper warnings."
    echo ""
    echo "To install:"
    echo "  1. Open $DMG_PATH"
    echo "  2. Drag WatchYourDay to Applications"
    echo ""
}

# Main execution
main() {
    echo ""
    echo "╔═══════════════════════════════════════╗"
    echo "║    WatchYourDay DMG Builder v1.1      ║"
    echo "╚═══════════════════════════════════════╝"
    echo ""
    
    mkdir -p "$BUILD_DIR"
    
    check_dependencies
    build_app
    create_dmg
    print_summary
}

main "$@"
