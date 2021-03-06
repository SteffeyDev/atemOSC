#
# Check if notarization creds exist
#
if [[ -z "${APPLE_DEVELOPER_EMAIL}" ]] ; then
	echo -e "${RED_COLOR}You must specify your Apple Developer Account email${NO_COLOR}"
	echo -e "EXPORT your email to an environment variable, for example:"
	echo -e "\techo 'export APPLE_DEVELOPER_EMAIL=\"example@test.com\"' >> ~/.bashrc"
	exit 1
fi
if [[ -z "${APPLE_DEVELOPER_PASSWORD}" ]] ; then
	echo -e "${RED_COLOR}You must specify your Apple Developer Account password${NO_COLOR}"
	echo -e "EXPORT your password to an environment variable, for example:"
	echo -e "\techo 'export APPLE_DEVELOPER_PASSWORD=\"my-secret-password\"' >> ~/.bashrc"
	echo -e "You can also store your password in a keychain entry and use the following instead:"
	echo -e "\techo 'export APPLE_DEVELOPER_PASSWORD=\"@keychain:MY_ENTRY_NAME\"' >> ~/.bashrc"
	exit 1
fi
if [[ -z "${APPLE_DEVELOPER_TEAM_SHORTNAME}" ]] ; then
	echo -e "${RED_COLOR}You must specify your Apple Developer Account team shortname for the team you would like to use${NO_COLOR}"
  echo -e "Run the command: xcrun altool --list-providers -u $APPLE_DEVELOPER_EMAIL -p $APPLE_DEVELOPER_PASSWORD"
	echo -e "EXPORT the team shortname to an environment variable, for example:"
	echo -e "\techo 'export APPLE_DEVELOPER_TEAM_SHORTNAME=\"ABCD1234\"' >> ~/.bashrc"
	exit 1
fi

if [[ -z $1 ]] ; then
  echo -e "Pass in the path to the atemOSC_X.Y.Z.dmg file as the first argument"
  exit 1
fi

echo "Uploading app for notarization. This may take a minute."
GIT_ROOT=$(git rev-parse --show-toplevel)
BUNDLE_ID=$(cat $GIT_ROOT/atemOSC/atemOSC.xcodeproj/project.pbxproj | grep PRODUCT_BUNDLE_IDENTIFIER | head -n 1 | xargs | cut -d" " -f3 | cut -d";" -f1)
xcrun altool --notarize-app --primary-bundle-id "$BUNDLE_ID" --username $APPLE_DEVELOPER_EMAIL --password $APPLE_DEVELOPER_PASSWORD --asc-provider $APPLE_DEVELOPER_TEAM_SHORTNAME --file $1
if [[ $? != 0 ]] ; then
  echo -e "${RED_COLOR}Error uploading for notarization.${NO_COLOR}"
  exit 1
fi
echo "Run command to check notarization status: xcrun altool --notarization-history 0 -u $APPLE_DEVELOPER_EMAIL -p $APPLE_DEVELOPER_PASSWORD --asc-provider $APPLE_DEVELOPER_TEAM_SHORTNAME"
