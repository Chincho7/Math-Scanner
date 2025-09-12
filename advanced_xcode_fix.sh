#!/bin/bash

echo "====================================================="
echo "   ADVANCED FIX FOR XCODE SCRIPT EXECUTION ERROR     "
echo "====================================================="
echo ""
echo "Creating helper scripts..."

# Create a fix script in the Flutter directory
cat > ios/Flutter/fix_xcode_script_phase.sh << 'EOL'
#!/bin/bash

# This script fixes issues with the Run Script phase in Xcode
# by ensuring the Flutter environment is correctly set up

# Get the Flutter root directory
FLUTTER_ROOT=$(which flutter | xargs dirname | xargs dirname)
if [[ -z "$FLUTTER_ROOT" ]]; then
  echo "Error: Flutter not found in PATH"
  exit 1
fi

# Set up environment variables
export FLUTTER_ROOT="$FLUTTER_ROOT"
export FLUTTER_APPLICATION_PATH="$(pwd)"
export FLUTTER_TARGET="lib/main.dart"
export FLUTTER_BUILD_DIR="build"
export FLUTTER_BUILD_NAME="1.0.0"
export FLUTTER_BUILD_NUMBER="1"
export EXCLUDED_ARCHS="i386"
export DART_OBFUSCATION="false"
export TRACK_WIDGET_CREATION="true"
export TREE_SHAKE_ICONS="false"
export PACKAGE_CONFIG=".dart_tool/package_config.json"

# Make sure Flutter tools are executable
chmod +x "$FLUTTER_ROOT/bin/flutter"
chmod +x "$FLUTTER_ROOT/bin/dart"

# Run the original script
if [[ -f "$FLUTTER_ROOT/packages/flutter_tools/bin/xcode_backend.sh" ]]; then
  chmod +x "$FLUTTER_ROOT/packages/flutter_tools/bin/xcode_backend.sh"
  "$FLUTTER_ROOT/packages/flutter_tools/bin/xcode_backend.sh" "$@"
else
  echo "Error: Flutter xcode_backend.sh not found"
  exit 1
fi
EOL

# Make it executable
chmod +x ios/Flutter/fix_xcode_script_phase.sh

echo ""
echo "Helper script created at ios/Flutter/fix_xcode_script_phase.sh"
echo ""
echo "====================================================="
echo "             XCODE MANUAL STEPS                      "
echo "====================================================="
echo ""
echo "Now, you need to update the Run Script phases in Xcode:"
echo ""
echo "1. Open Xcode (opening automatically now...)"
echo "2. Click on 'Runner' project in the left sidebar"
echo "3. Go to 'Build Phases' tab"
echo "4. For EACH 'Run Script' phase that uses xcode_backend.sh:"
echo "   a. Replace the script content with:"
echo "      sh \"${SRCROOT}/Flutter/fix_xcode_script_phase.sh\" [original arguments]"
echo "   b. Example for the Thin Binary phase:"
echo "      sh \"${SRCROOT}/Flutter/fix_xcode_script_phase.sh\" thin"
echo "   c. Example for the Run Script phase:"
echo "      sh \"${SRCROOT}/Flutter/fix_xcode_script_phase.sh\" build"
echo ""
echo "5. Clean the build folder (Product > Clean Build Folder)"
echo "6. Try building again"
echo ""
echo "Opening Xcode now..."
echo "====================================================="

# Open Xcode
open ios/Runner.xcworkspace
