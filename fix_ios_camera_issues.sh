#!/bin/bash
# Comprehensive iOS Camera Issue Fix Script
# This script helps resolve various issues with camera permissions and initialization in iOS Flutter apps

echo "🔍 Starting iOS Camera Issue Fix..."

# Set working directory to the project root
cd "$(dirname "$0")"
PROJECT_DIR=$(pwd)
echo "📂 Working directory: $PROJECT_DIR"

# Check if running on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
  echo "❌ Error: This script must be run on macOS"
  exit 1
fi

# Verify Flutter is installed
if ! command -v flutter &> /dev/null; then
  echo "❌ Error: Flutter is not installed or not in PATH"
  exit 1
fi

# Verify Xcode is installed
if ! command -v xcodebuild &> /dev/null; then
  echo "❌ Error: Xcode is not installed or not in PATH"
  exit 1
fi

# Step 1: Clean project
echo "🧹 Cleaning project..."
flutter clean
rm -rf build/ios
echo "✅ Project cleaned"

# Step 2: Remove Pod artifacts
echo "🧹 Cleaning iOS dependencies..."
rm -rf ios/Pods ios/Podfile.lock ios/Flutter/Flutter.podspec ios/.symlinks
echo "✅ iOS dependencies cleaned"

# Step 3: Fix resource fork issues
echo "🔧 Removing resource fork files..."
find ios -name "._*" -delete
find ios -name ".DS_Store" -delete
echo "✅ Resource fork files removed"

# Step 4: Update Flutter packages
echo "📦 Getting Flutter packages..."
flutter pub get
echo "✅ Flutter packages updated"

# Step 5: Check and update Info.plist
echo "🔍 Checking Info.plist for camera permissions..."
INFO_PLIST="ios/Runner/Info.plist"

# Check if Info.plist exists
if [ ! -f "$INFO_PLIST" ]; then
  echo "❌ Error: Info.plist not found at $INFO_PLIST"
  exit 1
fi

# Check for camera usage description
if ! grep -q "NSCameraUsageDescription" "$INFO_PLIST"; then
  echo "⚠️ Adding camera usage description to Info.plist..."
  # Find closing dict tag and add our key before it
  sed -i '' 's/<\/dict>/\t<key>NSCameraUsageDescription<\/key>\n\t<string>This app needs camera access to scan math problems<\/string>\n<\/dict>/g' "$INFO_PLIST"
  echo "✅ Camera usage description added to Info.plist"
else
  echo "✅ Camera usage description already present in Info.plist"
fi

# Step 6: Check the AppDelegate.swift file for camera permission code
echo "🔍 Checking AppDelegate.swift for camera permission handling..."
APP_DELEGATE="ios/Runner/AppDelegate.swift"

if [ -f "$APP_DELEGATE" ]; then
  if ! grep -q "AVFoundation" "$APP_DELEGATE"; then
    echo "⚠️ Adding camera permission request to AppDelegate.swift..."
    
    # Backup the original file
    cp "$APP_DELEGATE" "${APP_DELEGATE}.backup"
    
    # Add AVFoundation import
    sed -i '' 's/import UIKit/import UIKit\nimport AVFoundation/g' "$APP_DELEGATE"
    
    # Add camera permission request in didFinishLaunchingWithOptions
    sed -i '' 's/return super.application(application, didFinishLaunchingWithOptions: launchOptions)/\n    \/\/ Request camera permission early\n    AVCaptureDevice.requestAccess(for: .video) { _ in \n      \/\/ Permission requested\n    }\n    \n    return super.application(application, didFinishLaunchingWithOptions: launchOptions)/g' "$APP_DELEGATE"
    
    echo "✅ Camera permission request added to AppDelegate.swift"
  else
    echo "✅ AppDelegate.swift already contains camera permission handling"
  fi
else
  echo "⚠️ AppDelegate.swift not found at $APP_DELEGATE"
fi

# Step 7: Install iOS dependencies
echo "📱 Installing iOS dependencies..."
cd ios
pod install
cd ..
echo "✅ iOS dependencies installed"

# Step 8: Force camera permission for iOS
echo "🔧 Creating iOS camera permission fix file..."

cat > ios/Runner/CameraPermissionHelper.swift << 'EOF'
import Foundation
import AVFoundation

class CameraPermissionHelper {
    static func requestCameraPermission(completion: @escaping (Bool) -> Void) {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            DispatchQueue.main.async {
                completion(granted)
            }
        }
    }
}
EOF

echo "✅ Camera permission helper created"

# Step 9: Update build settings
echo "🔧 Updating build settings..."
cd ios
XCODEPROJ="Runner.xcodeproj"

# Check if the Xcode project exists
if [ -d "$XCODEPROJ" ]; then
  echo "🔧 Setting Swift version to 5.0..."
  /usr/libexec/PlistBuddy -c "Print :objects" "Runner.xcodeproj/project.pbxproj" | grep -o "[A-Z0-9]\{24\}" | while read -r uuid; do
    /usr/libexec/PlistBuddy -c "Print :objects:$uuid:buildSettings:SWIFT_VERSION" "Runner.xcodeproj/project.pbxproj" 2>/dev/null | grep -q "5.0" || {
      if /usr/libexec/PlistBuddy -c "Print :objects:$uuid:isa" "Runner.xcodeproj/project.pbxproj" 2>/dev/null | grep -q "XCBuildConfiguration"; then
        if /usr/libexec/PlistBuddy -c "Print :objects:$uuid:buildSettings" "Runner.xcodeproj/project.pbxproj" 2>/dev/null; then
          /usr/libexec/PlistBuddy -c "Set :objects:$uuid:buildSettings:SWIFT_VERSION 5.0" "Runner.xcodeproj/project.pbxproj" 2>/dev/null || true
        fi
      fi
    }
  done
  echo "✅ Swift version updated"
else
  echo "⚠️ Xcode project not found at $XCODEPROJ"
fi
cd ..

# Step 10: Build for iOS
echo "🔨 Building app for iOS..."
flutter build ios --no-codesign

# Step 11: Provide final instructions
echo ""
echo "✅ iOS Camera Fix Complete!"
echo ""
echo "Next Steps:"
echo "1. Open the project in Xcode: open ios/Runner.xcworkspace"
echo "2. Select a development team in the Signing & Capabilities tab"
echo "3. Run the app on your device"
echo ""
echo "If camera issues persist, try our Camera Test page in the app to help diagnose the problem."
echo ""
