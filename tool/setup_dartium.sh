#!/usr/bin/env bash

set -e

DARTIUM_DIST="dartium-linux-x64-release.zip";
SELENIUM_JAR="selenium-server.jar";

echo "Fetching Dartium "

curl "http://storage.googleapis.com/dart-archive/channels/stable/raw/latest/dartium/$DARTIUM_DIST" > $DARTIUM_DIST
curl "http://selenium-release.storage.googleapis.com/2.48/selenium-server-standalone-2.48.2.jar" > $SELENIUM_JAR

unzip -u $DARTIUM_DIST > /dev/null

rm $DARTIUM_DIST

mv dartium-* dartiumdir

export DARTIUM_BIN="$PWD/dartiumdir/chrome"

echo Pub install
pub install

echo "#!/usr/bin/env bash" | tee -a selenium-server
echo "exec java  -jar $PWD/$SELENIUM_JAR \"$@\"" | tee -a selenium-server
chmod +x selenium-server

CHROMEDRIVER="chromedriver.zip";

curl "http://chromedriver.storage.googleapis.com/2.14/chromedriver_linux64.zip" > $CHROMEDRIVER
unzip $CHROMEDRIVER

export PATH=$PATH":$PWD"

chmod +x chromedriver

ln -s "$PWD/dartiumdir/chrome" "$PWD/dartium"