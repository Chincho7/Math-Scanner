#!/bin/bash

echo "====================================================="
echo "     VS CODE TO iPHONE RUNNER HELPER                 "
echo "====================================================="
echo ""
echo "This script will help you run your app from VS Code to your iPhone."
echo ""

# Clean project
echo "Step 1: Cleaning project..."
flutter clean

# Get dependencies
echo "Step 2: Getting dependencies..."
flutter pub get

# Fix resource fork issues
echo "Step 3: Fixing resource fork issues (common cause of build failures)..."
find ios -name "*.xcassets" -exec xattr -cr {} \;
find ios -name "*.storyboard" -exec xattr -cr {} \;
find ios -name "*.xib" -exec xattr -cr {} \;
find ios -name "*.framework" -exec xattr -cr {} \;
find ios -name "*.xcworkspace" -exec xattr -cr {} \;
find ios -name "*.xcodeproj" -exec xattr -cr {} \;

# Set up environment
echo "Step 4: Setting up correct environment variables..."
FLUTTER_ROOT=$(which flutter | xargs dirname | xargs dirname)
echo "FLUTTER_ROOT=$FLUTTER_ROOT" > ios/.xcode.env.local
echo "FLUTTER_APPLICATION_PATH=$(pwd)" >> ios/.xcode.env.local
echo "FLUTTER_TARGET=lib/main.dart" >> ios/.xcode.env.local

# Install pods
echo "Step 5: Installing iOS dependencies..."
cd ios && pod install
cd ..

echo ""
echo "====================================================="
echo "     SOLUTION FOR VS CODE TO iPHONE                  "
echo "====================================================="
echo ""
echo "The core issue is that VS Code can't handle iOS code signing properly."
echo "Instead of trying to run directly from VS Code, use this approach:"
echo ""
echo "OPTION 1: Run from Xcode (RECOMMENDED)"
echo "----------------------------------------"
echo "1. Open Xcode from VS Code using this command:"
echo "   open ios/Runner.xcworkspace"
echo ""
echo "2. In Xcode:"
echo "   - Select your iPhone from the device dropdown"
echo "   - Click on 'Runner' project"
echo "   - Go to 'Signing & Capabilities'"
echo "   - Ensure 'Automatically manage signing' is checked"
echo "   - Select your Apple ID in Team dropdown"
echo "   - Click the Play button to run"
echo ""
echo "OPTION 2: Use VS Code with command line"
echo "----------------------------------------"
echo "1. In VS Code, create a new VS Code task (in .vscode/tasks.json):"
echo "   {
  \"version\": \"2.0.0\",
  \"tasks\": [
    {
      \"label\": \"Run on iPhone\",
      \"type\": \"shell\",
      \"command\": \"flutter build ios --debug && open ios/Runner.xcworkspace\",
      \"group\": {
        \"kind\": \"build\",
        \"isDefault\": true
      }
    }
  ]
}" 
echo ""
echo "2. Run this task from VS Code's Command Palette (Cmd+Shift+P)"
echo "   Type 'Tasks: Run Task' and select 'Run on iPhone'"
echo ""
echo "Opening Xcode now for you to run the app..."
echo ""

# Open Xcode
open ios/Runner.xcworkspace
