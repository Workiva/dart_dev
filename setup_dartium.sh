#!/usr/bin/env bash

set -e

DART_DIST="dartsdk-linux-x64-release.zip";
DARTIUM_DIST="dartium-linux-x64-release.zip";
SELENIUM_JAR="selenium-server.jar";

echo "Fetching dart sdk and Dartium "

curl "http://storage.googleapis.com/dart-archive/channels/stable/release/latest/sdk/$DART_DIST" > $DART_DIST
curl "http://storage.googleapis.com/dart-archive/channels/stable/raw/latest/dartium/$DARTIUM_DIST" > $DARTIUM_DIST
curl "http://selenium-release.storage.googleapis.com/2.48/selenium-server-standalone-2.48.2.jar" > $SELENIUM_JAR

unzip -u $DART_DIST > /dev/null
unzip -u $DARTIUM_DIST > /dev/null

rm $DART_DIST
rm $DARTIUM_DIST

mv dartium-* dartium

export DART_SDK="$PWD/dart-sdk"
export PATH="$DART_SDK/bin:$PATH"
export DARTIUM_BIN="$PWD/dartium/chrome"

echo Pub install
pub install

sudo echo "#!/usr/bin/env bash" | sudo tee -a /usr/local/bin/selenium-server
sudo echo "exec java  -jar $PWD/$SELENIUM_JAR \"$@\"" | sudo tee -a /usr/local/bin/selenium-server
sudo chmod +x /usr/local/bin/selenium-server

CHROMEDRIVER="chromedriver.zip";

curl "http://chromedriver.storage.googleapis.com/2.20/chromedriver_linux64.zip" > $CHROMEDRIVER
unzip $CHROMEDRIVER
sudo cp chromedriver /usr/bin/chromedriver
sudo chown root /usr/bin/chromedriver
sudo chmod +x /usr/bin/chromedriver
sudo chmod 755 /usr/bin/chromedriver

sudo ln -s "$PWD/dartium/chrome" /usr/local/bin/dartium