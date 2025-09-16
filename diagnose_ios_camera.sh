#!/bin/bash

echo "🔍 iOS Camera Permission Detection Tool"
echo "===================================="

# Function to display the script purpose
function display_purpose() {
    echo "This script helps diagnose and fix iOS camera permission issues"
    echo "It will check your iOS configuration and generate a comprehensive report"
    echo
}

display_purpose

# Step 1: Check Info.plist configuration
echo "📋 Step 1: Checking Info.plist camera configuration..."
INFO_PLIST="ios/Runner/Info.plist"

if [ -f "$INFO_PLIST" ]; then
    if grep -q "NSCameraUsageDescription" "$INFO_PLIST"; then
        echo "✅ Camera usage description found in Info.plist"
        # Extract the camera usage description
        DESCRIPTION=$(grep -A1 "NSCameraUsageDescription" "$INFO_PLIST" | grep -v "NSCameraUsageDescription" | sed 's/<[^>]*>//g' | xargs)
        echo "   Description: \"$DESCRIPTION\""
    else
        echo "❌ Camera usage description (NSCameraUsageDescription) missing in Info.plist"
        echo "   This is required for iOS camera access!"
    fi
else
    echo "❌ Info.plist not found at expected location: $INFO_PLIST"
fi

# Step 2: Check AppDelegate for camera permission code
echo
echo "📱 Step 2: Checking AppDelegate for camera permission code..."
APPDELEGATE_PATH="ios/Runner/AppDelegate.swift"

if [ -f "$APPDELEGATE_PATH" ]; then
    if grep -q "AVFoundation" "$APPDELEGATE_PATH"; then
        echo "✅ AVFoundation import found in AppDelegate"
    else
        echo "❌ AVFoundation import missing in AppDelegate"
    fi
    
    if grep -q "AVCaptureDevice.requestAccess" "$APPDELEGATE_PATH"; then
        echo "✅ Camera permission request code found in AppDelegate"
    else
        echo "❌ Camera permission request code missing in AppDelegate"
    fi
else
    echo "❌ AppDelegate.swift not found at expected location: $APPDELEGATE_PATH"
fi

# Step 3: Check camera plugin installation
echo
echo "🔌 Step 3: Checking camera plugin installation..."
PUBSPEC_PATH="pubspec.yaml"

if [ -f "$PUBSPEC_PATH" ]; then
    if grep -q "camera:" "$PUBSPEC_PATH"; then
        CAMERA_VERSION=$(grep "camera:" "$PUBSPEC_PATH" | sed 's/camera://' | xargs)
        echo "✅ Camera plugin found in pubspec.yaml (version: $CAMERA_VERSION)"
    else
        echo "❌ Camera plugin not found in pubspec.yaml"
    fi
    
    if grep -q "permission_handler:" "$PUBSPEC_PATH"; then
        PERMISSION_VERSION=$(grep "permission_handler:" "$PUBSPEC_PATH" | sed 's/permission_handler://' | xargs)
        echo "✅ Permission handler plugin found in pubspec.yaml (version: $PERMISSION_VERSION)"
    else
        echo "❌ Permission handler plugin not found in pubspec.yaml"
    fi
else
    echo "❌ pubspec.yaml not found at expected location: $PUBSPEC_PATH"
fi

# Step 4: Check for iOS camera privacy-sensitivity info
echo
echo "🔒 Step 4: Checking for iOS privacy settings entry points..."

if grep -q "Privacy - Camera Usage Description" ios/Runner/*.plist 2>/dev/null; then
    echo "✅ Privacy - Camera Usage Description found in plist files"
else
    echo "❌ Privacy - Camera Usage Description not found in plist files"
fi

# Step 5: Provide recommendations
echo
echo "📝 DIAGNOSIS AND RECOMMENDATIONS:"
echo "--------------------------------"

ISSUES_FOUND=false

if ! grep -q "NSCameraUsageDescription" "$INFO_PLIST" 2>/dev/null; then
    ISSUES_FOUND=true
    echo "1. Add camera usage description to Info.plist:"
    echo "   <key>NSCameraUsageDescription</key>"
    echo "   <string>Math Scanner needs camera access to scan math problems</string>"
fi

if ! grep -q "AVFoundation" "$APPDELEGATE_PATH" 2>/dev/null || ! grep -q "AVCaptureDevice.requestAccess" "$APPDELEGATE_PATH" 2>/dev/null; then
    ISSUES_FOUND=true
    echo "2. Update AppDelegate.swift to request camera permission on startup"
fi

if [ "$ISSUES_FOUND" = false ]; then
    echo "✅ No critical issues found in your configuration."
    echo
    echo "Since you're still experiencing problems with camera permissions, try these steps:"
    echo "1. Delete the app from your iPhone"
    echo "2. Power off your iPhone completely and turn it back on"
    echo "3. Run the app again from Xcode with a clean build"
    echo "   - In Xcode menu: Product > Clean Build Folder"
    echo "   - Then run the app on your device"
    echo
    echo "If permission still doesn't appear in settings after these steps, try:"
    echo "1. Temporarily change your app's bundle ID in Xcode"
    echo "2. Install with the new bundle ID"
    echo "3. Test if camera permissions work with the new ID"
else
    echo
    echo "Please fix the issues listed above and try again."
fi

echo
echo "Need to completely reset your iOS build environment?"
echo "Run: ./ios_camera_permission_reset.sh"
echo
