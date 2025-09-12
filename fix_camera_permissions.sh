#!/bin/zsh

# Script to clear camera package cache and fix permission issues
# Run from project root

echo "🔄 Starting camera permission fix..."

# Remove cached permission handler data
echo "🧹 Cleaning app data..."
flutter clean

# Fix iOS specific issues
echo "🔧 Fixing iOS-specific issues..."

# Fix resource fork issues with sudo (if needed)
echo "🔄 Removing resource forks from Flutter artifacts..."
sudo xattr -rc ~/flutter/bin/cache
sudo xattr -rc ios/

# Fix Flutter cache
echo "🔄 Rebuilding Flutter cache..."
rm -rf ~/flutter/bin/cache
flutter doctor

# Fix permissions in specific app directories
echo "🔄 Updating app build files..."
cd ios
rm -rf Pods
rm -rf .symlinks
rm -rf Flutter/Flutter.framework
pod install --repo-update
cd ..

echo "✅ Fixed permission issues. Now try these steps:"
echo "1. Uninstall app from device"
echo "2. Run the app (select Camera Test from menu)"
echo "3. Try all permission buttons on screen"
echo ""
echo "If still having issues, open Xcode and run directly from there:"
echo "   open ios/Runner.xcworkspace"
echo ""
