export TAG_NUMBER=$( echo $TRAVIS_TAG | sed 's/[^0-9.]*//g' )

# Update the version of the binary to match the tag
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $TAG_NUMBER" atemOSC/atemOSC-Info.plist

# Build the new binary and sign
xcodebuild -project atemOSC/atemOSC.xcodeproj -target AtemOSC
cp -R ${HOME}/build/${TRAVIS_REPO_SLUG}/atemOSC/build/Release/atemOSC.app ./
./.travis/sign.sh

# Create and validate the DMG
create-dmg atemOSC.app

# Move to output dir
mkdir output
mv "atemOSC $TAG_NUMBER.dmg" ./output/"atemOSC_$TAG_NUMBER.dmg"

# Zip .app and .app.dSYM for uploading
zip -r -q ./output/atemOSC.app.zip ${HOME}/build/${TRAVIS_REPO_SLUG}/atemOSC/build/Release/atemOSC.app
zip -r -q ./output/atemOSC.app.dSYM.zip ${HOME}/build/${TRAVIS_REPO_SLUG}/atemOSC/build/Release/atemOSC.app.dSYM

echo "TAG_NUMBER: $TAG_NUMBER"
echo "Output Files:"
ls output
