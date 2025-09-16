#!/bin/bash

echo "🔧 iOS Camera Permission Fix Script"
echo "=================================="

# Clean the Flutter build
echo "📱 Cleaning Flutter project..."
flutter clean

# Remove iOS build artifacts
echo "🗑️ Cleaning iOS build artifacts..."
rm -rf build/ios
rm -rf ios/Pods
rm -rf ios/Podfile.lock

# Remove resource forks that can cause issues
echo "🧹 Removing resource fork files..."
cd ios
find . -name "._*" -delete
cd ..

# Update Info.plist to ensure camera permissions are properly configured
echo "📝 Verifying Info.plist configuration..."
PERMISSION_TEXT="This app needs camera access to scan math problems"
INFO_PLIST="ios/Runner/Info.plist"

# Check if NSCameraUsageDescription exists and update it if needed
if grep -q "NSCameraUsageDescription" "$INFO_PLIST"; then
  echo "✓ Camera usage description exists in Info.plist"
else
  echo "⚠️ Adding camera usage description to Info.plist"
  # Add before the last </dict>
  sed -i '' 's/<\/dict>/    <key>NSCameraUsageDescription<\/key>\n    <string>'"$PERMISSION_TEXT"'<\/string>\n<\/dict>/g' "$INFO_PLIST"
fi

# Get Flutter dependencies
echo "📦 Getting Flutter dependencies..."
flutter pub get

# Install iOS pods
echo "🍎 Installing iOS pods..."
cd ios
pod install
cd ..

echo "✅ Fix completed! Please run the app again."
echo ""
echo "If camera permissions still don't appear in Settings, try these steps:"
echo "1. Delete the app from your iPhone"
echo "2. Restart your iPhone"
echo "3. Build and reinstall the app"
echo "4. When prompted for camera permissions, select 'Allow'"
echo ""
