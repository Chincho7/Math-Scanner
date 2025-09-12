#!/bin/bash

echo "====================================================="
echo "     FIXING XCODE BUILD SCRIPT EXECUTION ERROR        "
echo "====================================================="
echo ""
echo "Performing deep clean of iOS build artifacts..."
echo ""

# Clean Flutter
flutter clean

# Remove Pods directory and Podfile.lock
echo "Removing Pods directory and Podfile.lock..."
rm -rf ios/Pods
rm -f ios/Podfile.lock

# Clean DerivedData
echo "Cleaning Xcode DerivedData..."
rm -rf ~/Library/Developer/Xcode/DerivedData

# Remove Flutter/ephemeral directory
echo "Cleaning Flutter ephemeral directory..."
rm -rf ios/Flutter/ephemeral

# Fix Resource Fork issues
echo "Fixing resource fork issues..."
find ios -name "*.xcassets" -exec xattr -cr {} \;
find ios -name "*.storyboard" -exec xattr -cr {} \;
find ios -name "*.xib" -exec xattr -cr {} \;
find ios -name "*.framework" -exec xattr -cr {} \;
find ios -name "*.xcworkspace" -exec xattr -cr {} \;
find ios -name "*.xcodeproj" -exec xattr -cr {} \;

# Create .xcode.env.local file with correct Flutter root
echo "Creating correct Flutter environment file..."
echo "FLUTTER_ROOT=$(which flutter | xargs dirname | xargs dirname)" > ios/.xcode.env.local
echo "FLUTTER_APPLICATION_PATH=$(pwd)" >> ios/.xcode.env.local
echo "COCOAPODS_PARALLEL_CODE_SIGN=true" >> ios/.xcode.env.local
echo "FLUTTER_TARGET=lib/main.dart" >> ios/.xcode.env.local
echo "FLUTTER_BUILD_DIR=build" >> ios/.xcode.env.local
echo "FLUTTER_BUILD_NAME=1.0.0" >> ios/.xcode.env.local
echo "FLUTTER_BUILD_NUMBER=1" >> ios/.xcode.env.local
echo "EXCLUDED_ARCHS[sdk=iphonesimulator*]=i386" >> ios/.xcode.env.local
echo "DART_OBFUSCATION=false" >> ios/.xcode.env.local
echo "TRACK_WIDGET_CREATION=true" >> ios/.xcode.env.local
echo "TREE_SHAKE_ICONS=false" >> ios/.xcode.env.local
echo "PACKAGE_CONFIG=.dart_tool/package_config.json" >> ios/.xcode.env.local

# Get Flutter dependencies
echo "Getting Flutter dependencies..."
flutter pub get

# Install pods
echo "Installing Pods..."
cd ios && pod install --repo-update
cd ..

echo ""
echo "====================================================="
echo "     XCODE BUILD PREPARATION COMPLETE                 "
echo "====================================================="
echo ""
echo "Next steps:"
echo "1. Open Xcode: open ios/Runner.xcworkspace"
echo "2. In Xcode, go to Product > Clean Build Folder"
echo "3. Try running the app again on your device"
echo ""
echo "Opening Xcode workspace now..."

# Open Xcode workspace
open ios/Runner.xcworkspace
