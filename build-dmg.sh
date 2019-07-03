sh build.sh
sleep 1
rm /tmp/hallelujah-*.dmg
DATE_WITH_TIME=`date "+%Y%m%d-%H%M%S"`
./dictionary/node_modules/.bin/appdmg appdmg.json /tmp/hallelujah-${DATE_WITH_TIME}.dmg
