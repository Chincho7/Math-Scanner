#!/bin/bash

echo "🔄 iOS Native Camera Fix"
echo "======================="

# Make script exit on any error
set -e

echo "🧹 Step 1: Full iOS project cleanup..."

# Clean Flutter cache
flutter clean

# Remove iOS build artifacts and caches
rm -rf build/ios
rm -rf ios/Pods
rm -rf ios/Podfile.lock
rm -rf ios/Flutter/Flutter.podspec
rm -rf ios/.symlinks

# Remove resource fork files that can cause issues on macOS
echo "   Removing resource fork files..."
find ios -name "._*" -delete
find ios -name ".DS_Store" -delete

# Verify Info.plist
echo "📋 Step 2: Verifying Info.plist camera settings..."
INFO_PLIST="ios/Runner/Info.plist"

# Ensure NSCameraUsageDescription is present with clear message
if grep -q "NSCameraUsageDescription" "$INFO_PLIST"; then
  echo "✅ Camera usage description exists"
  # Extract the current description for inspection
  DESCRIPTION=$(grep -A 1 "NSCameraUsageDescription" "$INFO_PLIST" | grep -v "NSCameraUsageDescription" | sed 's/<[^>]*>//g' | xargs)
  echo "   Current description: \"$DESCRIPTION\""
else
  echo "⚠️ Adding NSCameraUsageDescription to Info.plist..."
  # Add before the last </dict>
  sed -i '' 's/<\/dict>/    <key>NSCameraUsageDescription<\/key>\n    <string>Math Scanner needs camera access to scan math problems<\/string>\n<\/dict>/g' "$INFO_PLIST"
fi

echo "📲 Step 3: Reinstalling dependencies..."

# Get Flutter dependencies
flutter pub get

# Reinstall iOS pods
cd ios
pod install
cd ..

echo "✅ iOS camera fix completed!"
echo ""
echo "Instructions to run on device:"
echo "1. Connect your iPhone"
echo "2. Run: flutter run --release"
echo "3. When prompted for camera permissions, tap 'Allow'"
echo ""
echo "If the white screen persists:"
echo "1. Delete the app from your iPhone"
echo "2. Restart your iPhone"
echo "3. Open Xcode with: open ios/Runner.xcworkspace"
echo "4. In Xcode: Product > Clean Build Folder"
echo "5. Run on device from Xcode"
