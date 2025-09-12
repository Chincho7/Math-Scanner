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
