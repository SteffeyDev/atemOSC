if [[ -z $1 ]] ; then
  echo -e "Pass in the path to the generated .xcarchive file as the first argument"
  exit 1
fi

filepath="$1/dSYMs/atemOSC.app.dSYM/Contents/Resources/DWARF/atemOSC"
echo $filepath
curl --http1.1 https://upload.bugsnag.com/ \
  -F apiKey=7cacc9f30e9d865554af8b579b7e1b91 \
  -F dsym=@$filepath \
  -F projectRoot=/Users/petersteffey/atemOSC/atemOSC
