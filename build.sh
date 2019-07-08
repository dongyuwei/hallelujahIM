xcodebuild -version
clang -v
rm -rf /tmp/hallelujah
xcodebuild -workspace hallelujah.xcworkspace/ -scheme hallelujah -configuration Release CONFIGURATION_BUILD_DIR=/tmp/hallelujah/build/release
