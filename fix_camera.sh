#!/bin/zsh

# Script to debug & fix camera permission issues
# Run from project root with ./fix_camera.sh

echo "🔍 Starting camera permission debug script..."

# 1. Clean Flutter cache
echo "🧹 Cleaning Flutter cache..."
flutter clean
flutter pub get

# 2. Fix iOS resource fork issues (common cause of camera problems)
echo "🔧 Fixing iOS resource fork issues..."
cd ios
rm -rf Pods
rm -rf .symlinks
rm -rf Flutter/Flutter.framework
rm -rf Flutter/Flutter.podspec

# Remove extended attributes from iOS folder
echo "🧩 Removing extended attributes..."
xattr -rc .

# Reinstall pods
echo "📦 Reinstalling Pods..."
pod cache clean --all
pod install --repo-update

cd ..

# 3. Fix camera permissions in iOS
echo "📱 Verifying camera permissions in Info.plist..."
if grep -q "NSCameraUsageDescription" ios/Runner/Info.plist; then
  echo "✅ Camera usage description exists in Info.plist"
else
  echo "⚠️ NSCameraUsageDescription missing in Info.plist - please add it manually"
fi

# 4. Run the app with verbose logging to catch camera issues
echo "🚀 Running app with verbose logging (will show permission issues)..."
echo "⚠️ When app starts, navigate to camera screen to test permissions"
echo "🔍 Looking for: AVCaptureDevice authorization status or permission_handler logs"

# If on macOS, use simulator, otherwise try physical device
if [ -n "$(flutter devices | grep iPhone)" ]; then
  echo "📲 Running on iPhone..."
  flutter run -v -d "$(flutter devices | grep iPhone | head -1 | awk '{print $2}')"
elif [ -n "$(flutter devices | grep ios)" ]; then
  echo "📲 Running on iOS simulator..."
  flutter run -v -d "$(flutter devices | grep ios | head -1 | awk '{print $2}')"
else
  echo "📱 Running on first available device..."
  flutter run -v
fi

# If running fails, suggest manual steps
echo "
🛠️ If still having issues:
1. Uninstall app from device/simulator
2. In Xcode: Open iOS/Runner.xcworkspace
3. Select Runner > Signing & Capabilities > Select your team
4. Product > Clean Build Folder
5. Run directly from Xcode
"

echo "✨ Debug script complete"
