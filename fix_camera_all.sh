#!/bin/bash
# Enhanced script to fix camera permission issues on iOS

echo "====================================================="
echo "       FIXING CAMERA PERMISSIONS FOR iOS"
echo "====================================================="

# Clean up previous build artifacts
echo "Cleaning up previous build artifacts..."
flutter clean

# Fix resource fork issues
echo "Removing resource fork files from iOS directory..."
find ./ios -name "._*" -delete
rm -rf build/ios

# Update the Info.plist with camera permissions
echo "Ensuring camera permissions are properly set in Info.plist..."

PLIST_FILE="./ios/Runner/Info.plist"

# Check if the file exists
if [ -f "$PLIST_FILE" ]; then
  # Check if NSCameraUsageDescription exists
  if grep -q "NSCameraUsageDescription" "$PLIST_FILE"; then
    echo "Camera usage description already exists in Info.plist"
  else
    echo "Adding camera usage description to Info.plist..."
    sed -i '' 's/<\/dict>/    <key>NSCameraUsageDescription<\/key>\n    <string>This app needs camera access to scan math problems from textbooks or handwritten notes<\/string>\n<\/dict>/g' "$PLIST_FILE"
  fi
else
  echo "Error: Info.plist not found at $PLIST_FILE"
  exit 1
fi

# Clean Pods
echo "Cleaning CocoaPods dependencies..."
rm -rf ios/Pods ios/Podfile.lock

# Get Flutter dependencies
echo "Getting Flutter dependencies..."
flutter pub get

# Install Pods
echo "Installing CocoaPods dependencies..."
cd ios && pod install && cd ..

echo "====================================================="
echo "       CAMERA PERMISSION FIX COMPLETED"
echo "====================================================="
echo ""
echo "Next steps:"
echo "1. Run the app on your iPhone"
echo "2. When prompted, grant camera permissions"
echo "3. If camera still doesn't work, go to:"
echo "   Settings > Math Scanner > Camera > Enable"
echo ""
echo "Running the app now..."
flutter run
