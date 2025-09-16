#!/bin/bash

echo "🔄 COMPLETE iOS CAMERA PERMISSION RESET"
echo "======================================"
echo "This script performs a complete reset of iOS camera permissions"
echo ""

# Step 1: Force close Xcode if it's running
echo "📱 Step 1: Closing any open Xcode instances..."
osascript -e 'tell application "Xcode" to quit' 2>/dev/null || true
killall Xcode 2>/dev/null || true
killall -9 Xcode 2>/dev/null || true

# Step 2: Complete cleanup
echo "🧹 Step 2: Complete project cleanup..."
flutter clean
rm -rf build/
rm -rf ios/build/
rm -rf ios/Pods/
rm -rf ios/Podfile.lock
rm -rf .dart_tool/
rm -rf ios/.symlinks/
rm -rf ios/Flutter/Flutter.podspec
rm -rf ios/Flutter/flutter_export_environment.sh
rm -rf ios/Flutter/Generated.xcconfig
find ios -name "._*" -delete
find ios -name ".DS_Store" -delete

# Step 3: Force update Info.plist
echo "📝 Step 3: Updating Info.plist with camera permissions..."
INFO_PLIST="ios/Runner/Info.plist"

# Check if backup exists, if not create one
if [ ! -f "${INFO_PLIST}.backup" ]; then
    cp "${INFO_PLIST}" "${INFO_PLIST}.backup"
    echo "Created Info.plist backup at ${INFO_PLIST}.backup"
fi

# Add NSCameraUsageDescription if it doesn't exist or update it
if grep -q "NSCameraUsageDescription" "$INFO_PLIST"; then
    # Update existing entry
    sed -i '' 's/<key>NSCameraUsageDescription<\/key>.*<string>.*<\/string>/<key>NSCameraUsageDescription<\/key>\
    <string>Math Scanner needs camera access to scan math problems. Please allow camera access.<\/string>/g' "$INFO_PLIST"
    echo "✓ Updated camera usage description in Info.plist"
else
    # Add new entry before last </dict>
    sed -i '' 's/<\/dict>/    <key>NSCameraUsageDescription<\/key>\
    <string>Math Scanner needs camera access to scan math problems. Please allow camera access.<\/string>\
<\/dict>/g' "$INFO_PLIST"
    echo "✓ Added camera usage description to Info.plist"
fi

# Step 4: Regenerate project
echo "🔄 Step 4: Regenerating project files..."
flutter pub get
pushd ios > /dev/null
pod install --repo-update
popd > /dev/null

# Step 5: Modify AppDelegate.swift to force permission request at startup
APPDELEGATE_PATH="ios/Runner/AppDelegate.swift"

echo "🔧 Step 5: Updating AppDelegate.swift to force early permission request..."
if [ -f "$APPDELEGATE_PATH" ]; then
    # Check if we need to add the import
    if ! grep -q "import AVFoundation" "$APPDELEGATE_PATH"; then
        # Add import statement at the top (after first import)
        sed -i '' '1s/^/import UIKit\nimport AVFoundation\n/' "$APPDELEGATE_PATH"
        echo "Added AVFoundation import to AppDelegate"
    else
        echo "AVFoundation import already exists in AppDelegate"
    fi

    # Check if we need to add the permission request
    if ! grep -q "AVCaptureDevice.requestAccess" "$APPDELEGATE_PATH"; then
        # Add permission request code inside didFinishLaunchingWithOptions
        sed -i '' '/didFinishLaunchingWithOptions.*{/a\
        // Request camera permission at app startup to ensure iOS registers it\
        AVCaptureDevice.requestAccess(for: .video) { granted in\
            print("Camera permission \(granted ? "granted" : "denied")")\
        }\
' "$APPDELEGATE_PATH"
        echo "Added camera permission request to AppDelegate"
    else
        echo "Camera permission request already exists in AppDelegate"
    fi
else
    echo "⚠️ AppDelegate.swift not found"
fi

echo ""
echo "✅ Complete reset finished! Important next steps:"
echo ""
echo "1. DELETE Math Scanner app from your iPhone"
echo "2. RESTART your iPhone completely (power off/on)"
echo "3. In Xcode, go to Product > Clean Build Folder"
echo "4. Run the app again from Xcode"
echo ""
echo "When the app first launches, it should immediately request camera permission."
echo "After allowing once, the Camera permission should appear in iPhone Settings."
echo ""
