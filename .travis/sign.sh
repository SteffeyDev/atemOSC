#!/bin/bash

if [[ "$TRAVIS_OS_NAME" == "osx" ]]; then
  CERTIFICATE_P12=Certificate.p12;
  echo $CERTIFICATE_OSX_P12 | base64 --decode > $CERTIFICATE_P12;
  KEYCHAIN=build.keychain;
  security create-keychain -p mysecretpassword $KEYCHAIN;
  security default-keychain -s $KEYCHAIN;
  security unlock-keychain -p mysecretpassword $KEYCHAIN;
  echo $CERTIFICATE_P12;
  echo $KEYCHAIN;
  echo $(which codesign);
  cat $CERTIFICATE_P12;
  ls
  security import $CERTIFICATE_P12 -k $KEYCHAIN -P "" -T $(which codesign);

  codesign --force --sign "Developer ID Application" atemOSC.app/Contents/Frameworks/VVBasics.framework/Versions/Current
  codesign --force --sign "Developer ID Application" atemOSC.app/Contents/Frameworks/VVOSC.framework/Versions/Current
  codesign --force --sign "Developer ID Application" atemOSC.app

fi