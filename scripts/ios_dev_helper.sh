#!/bin/bash
# iOS Development and Testing Script for VYB

echo "🍎 VYB iOS Development Helper"
echo "=============================="

# Check if device is connected
echo "📱 Checking connected iOS devices..."
xcrun devicectl list devices | grep "iPhone"

# Function to build for device
build_for_device() {
    echo "🔨 Building VYB for connected iPhone..."
    cd /Users/brad/Code/vyb-web/ios
    xcodebuild -project VYB.xcodeproj -scheme VYB -destination 'generic/platform=iOS' build
}

# Function to build for simulator
build_for_simulator() {
    echo "🔨 Building VYB for iOS Simulator..."
    cd /Users/brad/Code/vyb-web/ios
    xcodebuild -project VYB.xcodeproj -scheme VYB -destination 'platform=iOS Simulator,name=iPhone 17' build
}

# Function to run simulator
run_simulator() {
    echo "📱 Launching iOS Simulator..."
    open -a Simulator
    echo "To run the app: use Cmd+R in Xcode or install via 'xcrun simctl install booted /path/to/app'"
}

# Menu
echo ""
echo "Select an option:"
echo "1) Build for connected iPhone"
echo "2) Build for iOS Simulator" 
echo "3) Launch iOS Simulator"
echo "4) Exit"

read -p "Enter choice [1-4]: " choice

case $choice in
    1) build_for_device ;;
    2) build_for_simulator ;;
    3) run_simulator ;;
    4) echo "Goodbye! 👋"; exit 0 ;;
    *) echo "Invalid option" ;;
esac