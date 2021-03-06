#!/bin/bash

GENERATE_POST_BODY() {
  cat <<EOF
{
  "tag_name": "v$NEXT_RELEASE",
  "target_commitish": "master",
  "name": "v${NEXT_RELEASE}",
  "body": "* List changes in this version here",
  "draft": true,
  "prerelease": false
}
EOF
}

RED_COLOR="\033[0;31m"
GREY_COLOR="\033[0;37m"
NO_COLOR="\033[0m"

#
# Check if Github auth token exists
#
if [[ -z "${AUTOMATIC_RELEASE_GITHUB_TOKEN}" ]] ; then
	echo -e "${RED_COLOR}You must specify your Github auth token.${NO_COLOR}"
	echo -e "Visit https://github.com/settings/tokens and generate a new Personal Access Token with \"public_repo\" access only."
	echo -e "Then EXPORT the generated token to an environment variable, for example:"
	echo -e "\techo 'export AUTOMATIC_RELEASE_GITHUB_TOKEN=\"<your_generated_token>\"' >> ~/.bashrc"
	exit 1
fi

#
# Check if Homebrew is installed
#
echo "Checking for Homebrew"
which -s brew
if [[ $? != 0 ]] ; then
    # Install Homebrew
    echo "Please install Homebrew: https://brew.sh/"
    exit 1
else
    brew update
fi

#
# Check if Git is installed
#
echo "Checking for git"
which -s git
if [[ $? != 0 ]] ; then
    echo "Installing git"
    brew install git
fi
git --version

#
# Check if Node is installed
#
echo "Checking for Node"
which -s node
if [[ $? != 0 ]] ; then
    echo "Installing Node"
    brew install node
fi
echo "node $(node --version)"

#
# Check if Node Package Manager is installed
#
echo "Checking for NPM"
which -s npm
if [[ $? != 0 ]] ; then
    echo "Installing npm"
    brew install npm
fi
echo "npm v$(npm --version)"

#
# Check if create-dmg is installed
#
echo "Checking for create-dmg"
which -s create-dmg
if [[ $? != 0 ]] ; then
    echo "Installing create-dmg"
    npm install --global create-dmg
fi
echo "create-dmg v$(create-dmg --version)"

#
# Ensure correct repository status
#
echo "Checking git repository status"
if ! [ $(git rev-parse --abbrev-ref HEAD) == "master" ] ; then
	echo -e "${RED_COLOR}You must generate a release from \"master\", currently on branch: \"$(git rev-parse --abbrev-ref HEAD)\".${NO_COLOR}"
	echo -e "\tgit checkout master"
	exit 1
fi
# if origin isn't set
if [[ ! $(git config --get remote.origin.url) ]]
  then
    echo -e "Remote ${GREY_COLOR}origin${NO_COLOR} missing"
    echo -e "You need to specify the remote repository manually"
    echo "e.g. ${GREY_COLOR}git remote add origin https://github.com/SteffeyDev/atemOSC${NO_COLOR}"
	exit 1
fi

# Obtained valid 'origin' remote, set REPOSITORY now
REPOSITORY=$(git config --get remote.origin.url | sed -E 's/(https?:\/\/(www.)?github.com\/|git@github.com:)([A-Za-z]+\/[A-Za-z]+).*/\3/')

git pull origin master
if [[ $? != 0 ]] ; then
	echo -e "${RED_COLOR}Could not pull from origin master. Please resolve manually (perhaps you have local changes).${NO_COLOR}"
	exit 1
fi

# Create tag if needed
if [ $(git tag -l "v$VERSION" | wc -l | xargs) -eq 0 ]; then
  git tag -a "v$VERSION" -m "v$VERSION"
  git push --tags
fi

#
# Creating directory to work in
#
rm -rf temp_output
mkdir -p temp_output
cd temp_output

if [[ -z $1 ]] ; then
  echo -e "Pass in the path to the notarized atemOSC.app file as the first argument"
  exit 1
fi
cp -R "$1" .

#
# Generating DMG
#
echo "Generating DMG"
create-dmg 'atemOSC.app' || true
if [[ $? != 0 ]] ; then
  echo -e "${RED_COLOR}Could not generate DMG.${NO_COLOR}"
  exit 1
fi
FILENAME=$(find "atemOSC "*.dmg)
mv "$FILENAME" "${FILENAME// /_}"
FILENAME=$(find atemOSC_*.dmg)
NEXT_RELEASE=$(echo $FILENAME | sed -E 's/atemOSC_(.*).dmg/\1/')
echo -e "Generated: ${GREY_COLOR}${FILENAME}${NO_COLOR}"

#
# Notarize installer
#
./../notarize-dmg.sh $FILENAME
if [[ $? != 0 ]] ; then
  echo -e "${RED_COLOR}Notarization Failed.${NO_COLOR}"
  exit 1
fi

#
# GitHub Release
#
echo "Generating v${NEXT_RELEASE}"

RELEASE=$(curl --silent -H "Content-Type: application/json" -X POST --data "$(GENERATE_POST_BODY)" "https://api.github.com/repos/${REPOSITORY}/releases?access_token=${AUTOMATIC_RELEASE_GITHUB_TOKEN}")


EDIT_URL="$(node -p -e 'JSON.parse(process.argv[1]).html_url.replace('/\\/tag\\//', '/edit/')' "${RELEASE}")"

ASSET_URL="$(node -p -e 'JSON.parse(process.argv[1]).upload_url.replace('/\\{\\?name\,label\}/', '\"?name=${FILENAME}\"')' "${RELEASE}")"

echo "Uploading DMG file"

ASSET=$(curl --silent --data-binary @"$FILENAME" -H "Authorization: token $AUTOMATIC_RELEASE_GITHUB_TOKEN" -H "Content-Type: application/octet-stream" $ASSET_URL)

# Cleaning up
cd -
rm -rf temp_output

echo "✅  Release draft generated. Visit ${EDIT_URL}"
