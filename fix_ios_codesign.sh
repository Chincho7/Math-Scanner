#!/bin/bash

# Comprehensive iOS Build Fix Script
# This script fixes resource fork and codesigning issues

PROJECT_DIR="/Users/ninojaiani/Documents/Documents - Nino's MacBook Pro/MobileApps/Math Scanner"
cd "$PROJECT_DIR"

echo "🔧 Starting comprehensive iOS build fix..."

# Step 1: Clean everything thoroughly
echo "🧹 Cleaning all build artifacts..."
flutter clean
rm -rf ios/build
rm -rf build
rm -rf ios/Pods
rm -rf ios/Podfile.lock
rm -rf ios/.symlinks
rm -rf .dart_tool

# Step 2: Remove all resource forks and extended attributes
echo "🗑️  Removing resource forks and extended attributes..."
find . -name "._*" -delete
find . -name ".DS_Store" -delete
xattr -cr .
xattr -cr ios/

# Step 3: Fix specific Flutter framework issues
echo "🔨 Fixing Flutter framework signatures..."
FLUTTER_CACHE="$HOME/flutter/bin/cache/artifacts/engine"
if [ -d "$FLUTTER_CACHE" ]; then
    find "$FLUTTER_CACHE" -name "._*" -delete
    xattr -cr "$FLUTTER_CACHE"
fi

# Step 4: Get dependencies
echo "📦 Getting Flutter dependencies..."
flutter pub get

# Step 5: Install iOS dependencies
echo "🍎 Installing iOS pods..."
cd ios
pod deintegrate 2>/dev/null || true
pod install --repo-update
cd ..

# Step 6: Create a codesign fix script
echo "📝 Creating codesign fix script..."
cat > ios/fix_codesign.sh << 'EOF'
#!/bin/bash
# Remove resource forks from Flutter framework
find "$BUILT_PRODUCTS_DIR" -name "._*" -delete 2>/dev/null || true
find "$TARGET_BUILD_DIR" -name "._*" -delete 2>/dev/null || true

# Remove extended attributes
if [ -d "$BUILT_PRODUCTS_DIR/$WRAPPER_NAME" ]; then
    xattr -cr "$BUILT_PRODUCTS_DIR/$WRAPPER_NAME" 2>/dev/null || true
fi

if [ -d "$TARGET_BUILD_DIR/$WRAPPER_NAME" ]; then
    xattr -cr "$TARGET_BUILD_DIR/$WRAPPER_NAME" 2>/dev/null || true
fi

# Fix Flutter framework specifically
FLUTTER_FRAMEWORK="$BUILT_PRODUCTS_DIR/Flutter.framework"
if [ -d "$FLUTTER_FRAMEWORK" ]; then
    find "$FLUTTER_FRAMEWORK" -name "._*" -delete 2>/dev/null || true
    xattr -cr "$FLUTTER_FRAMEWORK" 2>/dev/null || true
fi
EOF

chmod +x ios/fix_codesign.sh

# Step 7: Try building without codesigning first
echo "🏗️  Building iOS without codesigning..."
flutter build ios --no-codesign --debug

# Step 8: If build succeeded, open Xcode
if [ $? -eq 0 ]; then
    echo "✅ Build successful! Opening Xcode..."
    open ios/Runner.xcworkspace
    
    echo ""
    echo "📱 Next steps in Xcode:"
    echo "1. Select your iPhone from the device dropdown"
    echo "2. Go to Runner target > Signing & Capabilities"
    echo "3. Enable 'Automatically manage signing'"
    echo "4. Select your development team"
    echo "5. Click the Play button to run on your device"
    echo ""
    echo "If you still get codesigning errors:"
    echo "- Go to Product > Clean Build Folder"
    echo "- Try running again"
else
    echo "❌ Build failed. Let's try a different approach..."
    
    # Alternative: Clean and rebuild with specific fixes
    echo "🔄 Trying alternative build approach..."
    
    # Remove any cached build artifacts
    rm -rf ~/Library/Developer/Xcode/DerivedData/*Math*Scanner* 2>/dev/null || true
    
    # Try building again
    flutter build ios --no-codesign --debug --verbose
    
    if [ $? -eq 0 ]; then
        echo "✅ Alternative build successful!"
        open ios/Runner.xcworkspace
    else
        echo "❌ Build still failing. Opening Xcode for manual debugging..."
        open ios/Runner.xcworkspace
        echo ""
        echo "🛠️  Manual steps to try in Xcode:"
        echo "1. Product > Clean Build Folder"
        echo "2. Check Build Settings > Code Signing"
        echo "3. Ensure iOS Deployment Target is set correctly"
        echo "4. Try building from Xcode directly"
    fi
fi
