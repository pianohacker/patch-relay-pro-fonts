#!/bin/bash -exu

cd $(dirname $BASH_SOURCE)

rm -rf output 
mkdir output

PASSWORD="$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | head -c 32)"

keytool -genkey \
	-v \
	-keystore output/release-key.keystore \
	-storepass "${PASSWORD}" \
	-dname "CN=reddit.news-patched" \
	-alias reddit.news-patched \
	-keyalg RSA \
	-keysize 2048 \
	-keypass "${PASSWORD}" \
	-validity 10000

adb shell su -c 'cp /data/app/reddit.news-*/base.apk /sdcard/reddit.news.apk' 
adb pull /sdcard/reddit.news.apk output/reddit.news.apk-unaligned

zip -d output/reddit.news.apk-unaligned 'META-INF/*'
zip output/reddit.news.apk-unaligned assets/fonts/*

zipalign -v 4 output/reddit.news.apk-unaligned output/reddit.news.apk
jarsigner \
	-verbose \
	-sigalg SHA1withRSA \
	-digestalg SHA1 \
	-keystore output/release-key.keystore \
	-storepass "${PASSWORD}" \
	output/reddit.news.apk \
	reddit.news-patched

adb shell su -c 'tar cz -C /data/data/reddit.news .' > output/reddit.news.backup.tgz
adb uninstall reddit.news

adb install output/reddit.news.apk
NEW_USERID=$(adb shell dumpsys package reddit.news | grep userId= | cut -d = -f 2)
adb shell su -c 'tar xz -C /data/data/reddit.news' < output/reddit.news.backup.tgz
adb shell su -c 'chown -R '${NEW_USERID}': /data/data/reddit.news'
