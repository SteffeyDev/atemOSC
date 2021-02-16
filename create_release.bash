#!/bin/bash

GH_USER=steffeydev
GH_TOKEN=`cat ~/.ghtoken`
GH_REPO=atemOSC
GH_TARGET=master
VERSION=$(cat atemOSC/atemOSC.xcodeproj/project.pbxproj | grep MARKETING_VERSION | head -n 1 | xargs | cut -d" " -f3 | cut -d";" -f1)
BUNDLE_ID=$(cat atemOSC/atemOSC.xcodeproj/project.pbxproj | grep PRODUCT_BUNDLE_IDENTIFIER | head -n 1 | xargs | cut -d" " -f3 | cut -d";" -f1)
DMG_NAME="atemOSC_$VERSION.dmg"

mkdir -p output
cd output

cp -R "$1" .

create-dmg atemOSC.app
mv "atemOSC $VERSION.dmg" $DMG_NAME

echo "Uploading app for notarization..."
xcrun altool --notarize-app --primary-bundle-id "$BUNDLE_ID" --username "steffeydev@icloud.com" --password "@keychain:APPLE_DEV_PWD" --asc-provider "LRNWZB2D4D" --file $DMG_NAME

git add -u
git commit -m "$VERSION release"

if [ $(git tag -l "v$VERSION" | wc -l | xargs) -eq 0 ]; then
  git tag -a "v$VERSION" -m "v$VERSION"
fi

git push

res=`curl --user "$GH_USER:$GH_TOKEN" -X POST https://api.github.com/repos/${GH_USER}/${GH_REPO}/releases \
  -H "Accept: application/vnd.github.v3+json" \
  -d "
  {
    \"tag_name\": \"v$VERSION\",
    \"target_commitish\": \"$GH_TARGET\",
    \"name\": \"v$VERSION\",
    \"body\": \"new version $VERSION\",
    \"draft\": false,
    \"prerelease\": false
  }"`
echo Create release result: ${res}
rel_id=`echo ${res} | python -c 'import json,sys;print(json.load(sys.stdin)["id"])'`

curl --user "$GH_USER:$GH_TOKEN" -X POST https://uploads.github.com/repos/${GH_USER}/${GH_REPO}/releases/${rel_id}/assets?name=${DMG_NAME} \
  -H 'Accept: application/vnd.github.v3+json' \
  -H 'Content-Type: application/octet-stream' \
  --upload-file ${DMG_NAME}

cd ..
rm -rf output

echo "Run command to check notarization status: xcrun altool --notarization-history 0 -u \"steffeydev@icloud.com\" -p \"@keychain:APPLE_DEV_PWD\" --asc-provider LRNWZB2D4D"
