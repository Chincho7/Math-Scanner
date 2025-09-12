#!/bin/bash

# Script to remove resource forks and extended attributes
# This helps fix iOS build issues with Flutter

echo "Removing resource forks and extended attributes..."
find "$PWD" -type f -name "*.framework*" -exec xattr -cr {} \;
find "$PWD" -type f -name "*.a" -exec xattr -cr {} \;
find "$PWD" -type f -name "*.xcframework*" -exec xattr -cr {} \;
find "$PWD/ios" -type f -exec xattr -cr {} \;
find "$PWD/build" -type f -name "*.framework*" -exec xattr -cr {} \;

echo "Cleaning specific Flutter directories..."
xattr -cr "$PWD/ios"
xattr -cr "$PWD/build"

echo "Done! Now try building your app."
