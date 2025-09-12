#!/bin/bash

echo "Running Math Scanner on iPhone from Xcode - UPDATED WITH FIXES"
echo "=========================================================="
echo ""
echo "Math Scanner app fixes implemented:"
echo "1. Fixed math solver service to better handle different math notations"
echo "2. Improved manual input screen with more operation buttons"
echo "3. Fixed equals sign handling"
echo ""
echo "Follow these steps in Xcode:"
echo ""
echo "1. Make sure your iPhone is selected in the device dropdown at the top of Xcode"
echo "2. Click on the 'Runner' project in the left sidebar"
echo "3. Go to 'Signing & Capabilities' tab"
echo "4. Make sure 'Automatically manage signing' is checked"
echo "5. Select your personal Apple ID in the 'Team' dropdown"
echo "6. Update the Bundle Identifier if needed (make it unique, like com.yourname.mathscanner)"
echo "7. Press the Play (▶) button at the top left to build and run on your device"
echo ""
echo "If you encounter signing issues, try:"
echo "- Restarting Xcode"
echo "- Restarting your iPhone"
echo "- Disconnecting and reconnecting your iPhone"
echo "- Making sure your Apple ID is properly set up in Xcode → Preferences → Accounts"
echo ""
echo "Xcode should already be open. If not, run this command:"
echo "open ios/Runner.xcworkspace"

# Open Xcode workspace if it's not already open
if ! pgrep -x "Xcode" > /dev/null; then
    open "ios/Runner.xcworkspace"
fi
