#!/bin/bash

cd "$(dirname $0)"
PROJECT_ROOT=$(cd ..; pwd)

Version=`date "+%Y%m%d%H%M%S"`

# pushd ${PROJECT_ROOT}
# sh build.sh
# popd

rm /tmp/hallelujah-*.pkg
rm -rf /tmp/hallelujah/build/release/root/
mkdir -p /tmp/hallelujah/build/release/root
cp -R /tmp/hallelujah/build/release/hallelujah.app /tmp/hallelujah/build/release/root/

install_location="$HOME/Library/Input Methods"

pkgbuild \
    --info "${PROJECT_ROOT}/package/PackageInfo" \
    --root "/tmp/hallelujah/build/release/root" \
    --identifier "github.dongyuwei.inputmethod.hallelujahInputMethod" \
    --version ${Version} \
    --install-location "$install_location" \
    --scripts "${PROJECT_ROOT}/package/scripts" \
    --allowCurrentUserHome true \
    /tmp/hallelujah-${Version}.pkg
