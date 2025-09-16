#!/bin/zsh

echo "========= Math Scanner iOS Build Script ========="
echo "This script will clean your project and fix code signing issues"
echo "======================================================"

# Make sure we have sudo permission for xattr commands
echo "\n🔑 You may be prompted for your password to run sudo commands\n"

# Fix permission issues with Flutter frameworks
echo "🧹 Cleaning Flutter frameworks and removing resource forks..."

# Fix Flutter SDK frameworks
echo "✅ Fixing Flutter SDK frameworks..."
sudo xattr -cr ~/flutter/bin/cache/artifacts/engine/ios/Flutter.xcframework || true
sudo xattr -cr ~/flutter/bin/cache/artifacts/engine/ios-release/Flutter.xcframework || true

# Create a clean build
echo "🧹 Cleaning Flutter project..."
flutter clean

echo "📦 Getting dependencies..."
flutter pub get

# Navigate to iOS folder
cd ios

echo "🧹 Cleaning CocoaPods cache..."
rm -rf Pods
rm -rf Podfile.lock
rm -rf ~/Library/Developer/Xcode/DerivedData/*Runner* || true

echo "♻️ Reinstalling pods..."
pod deintegrate || true
pod setup
pod install

# Go back to project root
cd ..

echo "✅ iOS project setup complete!"
echo "📱 Running on device with special parameters..."

# Use a special build command with extra parameters
flutter build ios --debug --no-codesign

echo "📱 Now opening Xcode - please run from there"
open ios/Runner.xcworkspace

echo "\n⚠️ IMPORTANT: In Xcode, make sure to:"
echo "  1. Select your iPhone from the device dropdown"
echo "  2. Go to Runner > Signing & Capabilities"
echo "  3. Check 'Automatically manage signing'"
echo "  4. Select your personal team"
echo "  5. Click the Run (play) button"
