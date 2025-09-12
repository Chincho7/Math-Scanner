#!/bin/bash

# Clear the terminal screen
clear

echo "====================================================="
echo "     MATH SCANNER APP - RUN ON iPHONE HELPER         "
echo "====================================================="
echo ""
echo "Follow these simple steps to run on your iPhone:"
echo ""
echo "STEP 1: Make sure your iPhone is connected via USB"
echo "STEP 2: Unlock your iPhone"
echo "STEP 3: Trust your computer if prompted on iPhone"
echo ""
echo "Checking for connected iPhone..."

# Open Xcode
echo "Opening Xcode (this may take a moment)..."
open ios/Runner.xcworkspace

echo ""
echo "====================================================="
echo "             XCODE INSTRUCTIONS                       "
echo "====================================================="
echo ""
echo "In Xcode:"
echo ""
echo "1. At the top of Xcode, select your iPhone from device dropdown"
echo "   (It should show 'Nino's iPhone')"
echo ""
echo "2. Click on 'Runner' in the left sidebar"
echo ""
echo "3. Go to the 'Signing & Capabilities' tab"
echo ""
echo "4. Make sure 'Automatically manage signing' is checked"
echo ""
echo "5. Select your Apple ID in the 'Team' dropdown"
echo ""
echo "6. Click the Play ▶️ button at the top left"
echo ""
echo "====================================================="
echo ""
echo "NOTE: If you get a signing error in Xcode:"
echo "- Go to iPhone Settings → General → Device Management"
echo "- Trust your developer certificate"
echo ""
echo "If the app runs but math isn't working, please let me know!"
echo "====================================================="
