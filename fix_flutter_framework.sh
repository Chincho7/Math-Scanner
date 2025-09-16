#!/bin/zsh

echo "Fixing Flutter framework resource fork issues..."

# Find and fix all Flutter.framework files in the system
echo "Removing extended attributes from Flutter SDK frameworks..."
sudo xattr -cr ~/flutter/bin/cache/artifacts/engine/ios/Flutter.xcframework
sudo xattr -cr ~/flutter/bin/cache/artifacts/engine/ios-release/Flutter.xcframework

# Fix the build directory
echo "Removing extended attributes from project build files..."
if [ -d "build/ios" ]; then
  sudo xattr -cr build/ios
fi

# Also check for Flutter.framework in the local build directory
if [ -d "build/ios/Release-iphoneos/Flutter.framework" ]; then
  sudo xattr -cr build/ios/Release-iphoneos/Flutter.framework
fi

echo "Cleaning Flutter project..."
flutter clean

echo "Getting dependencies..."
flutter pub get

echo "Cleaning CocoaPods..."
cd ios
rm -rf Pods
rm -f Podfile.lock

echo "Installing pods..."
pod deintegrate || true
pod setup
pod install

echo "Done! Now open Runner.xcworkspace in Xcode and try building from there."
echo "Make sure to select your personal team for signing in Xcode's Signing & Capabilities tab."

# Open Xcode workspace
open Runner.xcworkspace
