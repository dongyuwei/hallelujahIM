mkdir -p ${HOME}/.hallelujah/debug
xcodebuild -workspace hallelujah.xcworkspace/ -scheme hallelujah -configuration Release CONFIGURATION_BUILD_DIR=${HOME}/.hallelujah/debug
pkill -9 hallelujah
sudo rm -rf  /Library/Input\ Methods/hallelujah.app/
sudo cp -R ${HOME}/.hallelujah/debug/hallelujah.app /Library/Input\ Methods/hallelujah.app