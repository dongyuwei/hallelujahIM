#!/bin/bash

# pinyin mode needs librime; fetch the pinned prebuild if it is not there yet
sh scripts/get-librime.sh

xcodebuild -version
clang -v
rm -rf /tmp/hallelujah

xcodebuild clean -workspace hallelujah.xcworkspace/ -scheme hallelujah

xcodebuild -workspace hallelujah.xcworkspace/ -scheme hallelujah -destination "generic/platform=macOS,name=Any Mac" -configuration "Release" CONFIGURATION_BUILD_DIR=/tmp/hallelujah/build/release BUILD_LIBRARY_FOR_DISTRIBUTION=YES



