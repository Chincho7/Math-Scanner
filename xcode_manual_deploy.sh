#!/bin/bash

echo "🎯 Final iOS Deployment via Xcode"
echo "Using Xcode directly to bypass Flutter CLI codesigning issues..."

# Navigate to project directory
cd "/Users/ninojaiani/Documents/Documents - Nino's MacBook Pro/MobileApps/Math Scanner"

# Step 1: Clean everything first
echo "📝 Step 1: Complete cleanup..."
flutter clean
rm -rf build/
rm -rf ios/build/
rm -rf ~/Library/Developer/Xcode/DerivedData/Runner-*

# Step 2: Get dependencies
echo "📝 Step 2: Getting dependencies..."
flutter pub get

# Step 3: Clean pods
echo "📝 Step 3: Reinstalling pods..."
cd ios
rm -rf Pods/ Podfile.lock
pod install --clean-install
cd ..

# Step 4: Generate iOS bundle first without running
echo "📝 Step 4: Pre-building iOS assets..."
flutter build ios --debug --no-codesign

# Step 5: Open Xcode for manual deployment
echo "📝 Step 5: Opening Xcode for manual deployment..."
echo ""
echo "🎯 MANUAL STEPS REQUIRED:"
echo "1. Xcode will open shortly"
echo "2. Select 'Nino's iPhone' as the target device"
echo "3. Go to Runner target > Signing & Capabilities"
echo "4. Ensure your Apple Developer account is selected"
echo "5. Click the ▶️ Play button to build and run"
echo ""
echo "This bypasses Flutter CLI codesigning issues!"
echo ""

# Open Xcode workspace
open ios/Runner.xcworkspace

echo "✅ Xcode opened! Please deploy manually using the steps above."
