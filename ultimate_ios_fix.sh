#!/bin/bash

echo "🔧 Ultimate iOS Resource Fork Fix & Deployment Script"
echo "Fixing resource fork issues and deploying to iPhone..."

# Navigate to project directory
cd "/Users/ninojaiani/Documents/Documents - Nino's MacBook Pro/MobileApps/Math Scanner"

# Step 1: Aggressive resource fork cleanup
echo "📝 Step 1: Aggressive resource fork cleanup..."
sudo find . -name "._*" -delete 2>/dev/null
sudo find . -name ".DS_Store" -delete 2>/dev/null
sudo xattr -rc . 2>/dev/null
sudo xattr -rc ios/ 2>/dev/null
sudo xattr -rc build/ 2>/dev/null

# Step 2: Clean all build artifacts
echo "📝 Step 2: Cleaning all build artifacts..."
flutter clean
rm -rf build/
rm -rf ios/build/
rm -rf ~/Library/Developer/Xcode/DerivedData/Runner-*
rm -rf ~/Library/Developer/Xcode/DerivedData/
rm -rf ios/.symlinks/
rm -rf ios/Flutter/ephemeral/

# Step 3: Fix Flutter framework resource forks specifically
echo "📝 Step 3: Fixing Flutter framework..."
FLUTTER_FRAMEWORK="/Users/ninojaiani/flutter/bin/cache/artifacts/engine/ios/Flutter.xcframework"
if [ -d "$FLUTTER_FRAMEWORK" ]; then
    sudo xattr -rc "$FLUTTER_FRAMEWORK" 2>/dev/null
    sudo find "$FLUTTER_FRAMEWORK" -name "._*" -delete 2>/dev/null
fi

# Step 4: Clean and reinstall dependencies
echo "📝 Step 4: Reinstalling dependencies..."
flutter pub get

# Step 5: Clean and reinstall pods with resource fork fixes
echo "📝 Step 5: Cleaning and reinstalling CocoaPods..."
cd ios
rm -rf Pods/
rm -rf Podfile.lock
rm -rf .symlinks/
pod deintegrate 2>/dev/null
pod install --clean-install --repo-update

# Step 6: Fix any remaining resource forks in pods
echo "📝 Step 6: Fixing pods resource forks..."
if [ -d "Pods" ]; then
    sudo xattr -rc Pods/ 2>/dev/null
    sudo find Pods/ -name "._*" -delete 2>/dev/null
fi

cd ..

# Step 7: Create clean build environment
echo "📝 Step 7: Creating clean build environment..."
flutter precache --ios

# Step 8: Fix codesigning issues
echo "📝 Step 8: Fixing codesigning..."
codesign --remove-signature build/ios/Debug-iphoneos/Flutter.framework/Flutter 2>/dev/null || true

# Step 9: Try Flutter run with verbose output
echo "📝 Step 9: Attempting iPhone deployment..."
echo "🚀 Running on iPhone with verbose output..."

flutter run -d "00008110-001559CE0109A01E" --verbose

echo "✅ Deployment attempt complete!"
