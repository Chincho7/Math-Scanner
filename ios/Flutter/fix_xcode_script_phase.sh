#!/bin/sh

# This script works around resource fork issues in Xcode script phases
# It's a wrapper around the original xcode_backend.sh

# Get the original arguments
ARGS=$@

# Locate the xcode_backend.sh script
FLUTTER_ROOT=$(which flutter | xargs dirname | xargs dirname)
BACKEND_SCRIPT="$FLUTTER_ROOT/packages/flutter_tools/bin/xcode_backend.sh"

# Remove extended attributes from the script
xattr -cr "$BACKEND_SCRIPT" || true

# Execute the original script with the original arguments
"$BACKEND_SCRIPT" $ARGS
