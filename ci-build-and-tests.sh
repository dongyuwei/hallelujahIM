rm Podfile.lock
rm -rf Pods
pod install

sh build.sh
sh unit-tests.sh
