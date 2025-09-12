#!/bin/bash

# Script to run the Math Scanner app from VS Code

# Set the directory to the Math Scanner project
PROJECT_DIR="$HOME/Documents/Documents - Nino's MacBook Pro/MobileApps/Math Scanner"
cd "$PROJECT_DIR"

# Function to check available devices
check_devices() {
  echo "📱 Checking available devices..."
  flutter devices
}

# Function to run on web
run_web() {
  echo "🌐 Running on Web..."
  flutter run -d chrome
}

# Function to run on macOS
run_macos() {
  echo "🖥️ Running on macOS..."
  flutter run -d macos
}

# Function to prepare for iPhone
run_iphone_prep() {
  echo "📱 Preparing for iPhone..."
  # Clean flutter build
  flutter clean
  
  # Get dependencies
  flutter pub get
  
  # Fix resource fork issues
  find ios -name "._*" -delete
  find ios -name ".DS_Store" -delete
  xattr -cr ios/
  
  # Update pods
  cd ios
  rm -rf Pods Podfile.lock
  pod install
  cd ..
  
  # Build for iOS
  flutter build ios --no-codesign
  
  # Open in Xcode
  open ios/Runner.xcworkspace
  
  echo "✅ Now complete the build in Xcode by selecting your device and clicking the run button."
}

# Display menu
echo "================================"
echo "   Math Scanner Runner Script   "
echo "================================"
echo "Please select where to run the app:"
echo "1) Web Browser"
echo "2) macOS Desktop"
echo "3) iPhone (via Xcode)"
echo "4) Check available devices"
echo "5) Exit"
echo "================================"

# Get user choice
read -p "Enter your choice (1-5): " choice

# Process the choice
case $choice in
  1) run_web ;;
  2) run_macos ;;
  3) run_iphone_prep ;;
  4) check_devices ;;
  5) echo "Exiting script"; exit 0 ;;
  *) echo "Invalid choice"; exit 1 ;;
esac
