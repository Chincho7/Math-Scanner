#!/bin/bash

# Quick Resource Fork Fix for iOS
PROJECT_DIR="/Users/ninojaiani/Documents/Documents - Nino's MacBook Pro/MobileApps/Math Scanner"
cd "$PROJECT_DIR"

echo "🔧 Quick iOS resource fork fix..."

# Remove resource forks
find . -name "._*" -delete 2>/dev/null || true
xattr -cr . 2>/dev/null || true

# Clean Flutter cache specifically
FLUTTER_CACHE="$HOME/flutter/bin/cache"
if [ -d "$FLUTTER_CACHE" ]; then
    find "$FLUTTER_CACHE" -name "._*" -delete 2>/dev/null || true
    xattr -cr "$FLUTTER_CACHE" 2>/dev/null || true
fi

# Clean derived data
rm -rf ~/Library/Developer/Xcode/DerivedData/*Math*Scanner* 2>/dev/null || true

# Clean build directory
rm -rf build/ 2>/dev/null || true

echo "✅ Resource forks cleaned. Trying to run on iPhone..."

# Try running directly on iPhone
flutter run -d "00008110-001559CE0109A01E"
