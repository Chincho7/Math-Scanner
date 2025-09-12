#!/bin/bash

# Change to the project directory
cd "$(dirname "$0")"

echo "Cleaning resource forks in iOS directory..."

# Remove .DS_Store files
find ./ios -name ".DS_Store" -delete

# Remove resource forks and extended attributes
find ./ios -not -path "*/\.*" -exec xattr -c {} \;

echo "Cleaning Flutter directory..."
rm -rf ./ios/Flutter/Flutter.framework
rm -rf ./ios/Flutter/Flutter.podspec
rm -rf ./ios/Flutter/ephemeral

echo "Cleaning Pods..."
rm -rf ./ios/Pods
rm -rf ./ios/Podfile.lock

echo "Cleaning build directory..."
rm -rf ./ios/build

echo "Cleaning is complete. Now run: flutter pub get && cd ios && pod install && cd .."
