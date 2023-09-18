rm Podfile.lock
rm -rf Pods
pod install

echo "===================tests===================="
sh unit-tests.sh

echo "=================build App=================="
sh build.sh
