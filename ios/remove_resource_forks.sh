#!/bin/bash

# This script removes extended attributes from frameworks
# to prevent code signing errors during iOS builds

echo "Removing resource forks from frameworks..."

# Find all framework directories in the build path and remove extended attributes
find "${BUILT_PRODUCTS_DIR}" -name "*.framework" -type d | while read -r FRAMEWORK
do
    echo "Cleaning framework: ${FRAMEWORK}"
    xattr -cr "${FRAMEWORK}"
done

# Find all XCFrameworks
find "${BUILT_PRODUCTS_DIR}" -name "*.xcframework" -type d | while read -r XCFRAMEWORK
do
    echo "Cleaning xcframework: ${XCFRAMEWORK}"
    xattr -cr "${XCFRAMEWORK}"
done

echo "Resource fork cleaning completed"
