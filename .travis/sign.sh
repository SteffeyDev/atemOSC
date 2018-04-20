#!/bin/bash

if [[ "$TRAVIS_OS_NAME" == "osx" ]]; then
  CERTIFICATE_P12=Certificate.p12;
  echo $CERTIFICATE_OSX_P12 | base64 --decode > $CERTIFICATE_P12;
  KEYCHAIN=build.keychain;
  security create-keychain -p mysecretpassword $KEYCHAIN;
  security default-keychain -s $KEYCHAIN;
  security unlock-keychain -p mysecretpassword $KEYCHAIN;
  security import $CERTIFICATE_P12 -k $KEYCHAIN -P "" -T $(which codesign);
  security set-key-partition-list -S apple-tool:,apple: -s -k mysecretpassword $KEYCHAIN

  codesign --force --sign "Developer ID Application" atemOSC.app/Contents/Frameworks/VVBasics.framework/Versions/Current
  codesign --force --sign "Developer ID Application" atemOSC.app/Contents/Frameworks/VVOSC.framework/Versions/Current
  codesign --force --sign "Developer ID Application" atemOSC.app

fi
