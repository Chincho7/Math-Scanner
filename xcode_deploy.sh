#!/bin/bash

echo "🔧 Comprehensive Xcode deployment fix script"
echo "Cleaning resource forks and deploying via Xcode..."

# Navigate to project directory
cd "/Users/ninojaiani/Documents/Documents - Nino's MacBook Pro/MobileApps/Math Scanner"

# Step 1: Clean resource forks more aggressively
echo "📝 Step 1: Removing resource forks..."
find . -name "._*" -delete 2>/dev/null
find . -name ".DS_Store" -delete 2>/dev/null
xattr -cr . 2>/dev/null
xattr -cr ios/ 2>/dev/null
xattr -cr build/ 2>/dev/null

# Step 2: Clean Flutter build cache
echo "📝 Step 2: Cleaning Flutter cache..."
flutter clean

# Step 3: Remove derived data 
echo "📝 Step 3: Cleaning Xcode derived data..."
rm -rf ~/Library/Developer/Xcode/DerivedData/Runner-*

# Step 4: Remove build directories
echo "📝 Step 4: Removing build directories..."
rm -rf build/
rm -rf ios/build/

# Step 5: Get dependencies
echo "📝 Step 5: Getting Flutter dependencies..."
flutter pub get

# Step 6: Clean and reinstall pods
echo "📝 Step 6: Cleaning and reinstalling CocoaPods..."
cd ios
rm -rf Pods/
rm -rf Podfile.lock
pod deintegrate
pod install --clean-install
cd ..

# Step 7: Open Xcode project for manual deployment
echo "📝 Step 7: Opening Xcode for manual deployment..."
echo "⚠️  Manual steps required:"
echo "1. Select your iPhone device in Xcode"
echo "2. Go to Runner target > Signing & Capabilities"
echo "3. Select your development team"
echo "4. Click the Play button to build and run"
echo ""
echo "🚀 Opening Xcode now..."
open ios/Runner.xcworkspace

echo "✅ Setup complete! Please use Xcode to deploy to your iPhone."
