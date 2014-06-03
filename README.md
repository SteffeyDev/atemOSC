# atemOSC v2.3.2

## Changelog v2.3.2
- update to Blackmagic SDK 5.1

## Changelog v2.3.1
- prevent AppNap on Mavericks (thanks to @thetzel)

## Changelog v2.3.0
 - bugfixes
 - using Blackmagic SDK 4.2
 - enhancements for Mac OS 10.9

## Changelog v2.2.2
 - fixed numbering of upstream keyers
 - added toggle functionality for keyers
 
## Changelog v2.2.1
 - support for Mac OS 10.7 (updated binary)

## Changelog v2.2
 - added support for controlling Upstream Keyers
 - supports all available input-sources, depending on your switcher
 - added help-menu with all OSC-addresses available

## Features
This is a Mac OS X application, providing an interface to control an ATEM video switcher via OSC. 
The code is based on the *SwitcherPanel*-Democode (Version 3.5) provided by Blackmagic. 	Additionally the control of a tally-light interface via Arduino is provided.

![atemOSC](https://github.com/danielbuechele/atemOSC/raw/master/atemOSC.jpg)

- [VVOSC](http://code.google.com/p/vvopensource/) is used as OSC-framework.
- [AMSerialPort](https://github.com/smokyonion/AMSerialPort) is used for Arduino-connection

The current version is built for Mac OS 10.7 SDK (as of version 2.2.1). A compiled and runnable version of the atemOSC is included. Caution: The software lacks of many usability features (like input validation).

----------

Program and preview selection as well as transition control are exposed via following OSC addresses:

 - **Cam 1** `/atem/program/1`
 - **Cam 2** `/atem/program/2`
 - **Cam 3** `/atem/program/3`
 - **Cam 4** `/atem/program/4`
 - **Cam 5** `/atem/program/5`
 - **Cam 6** `/atem/program/6`
 - and so on...
  
 - **Black** `/atem/program/0`
 - **Bars** `/atem/program/7`
 - **Color 1** `/atem/program/8`
 - **Color 2** `/atem/program/9`
 - **Media 1** `/atem/program/10`
 - **Media 2** `/atem/program/12`

For preview selection `/atem/preview/$i` can be used.

 - **T-bar** `/atem/transition/bar`
 - **Cut** `/atem/transition/cut`
 - **auto** `/atem/transition/auto`
 - **fade-to-black** `/atem/transition/ftb`
 
 - **Toggle Upstream Keyer 1** `/atem/usk/1` (up to `/atem/usk/4`, depends on your ATEM switcher)
 - **Prepare Upstream Keyer 1** `/atem/nextusk/1`  (up to `/atem/nextusk/4`, depends on your ATEM switcher)

 - **Toggle Downstreamkeyer 1** `/atem/dsk/1` (up to `/atem/dsk/4`, depends on your ATEM switcher)
 
All OSC-addresses expect float-values between 0.0 and 1.0.
**A full overview of all OSC-addresses available for your switcher can be obtained from the help-menu inside the application.**

----------

I am using this software with TouchOSC on the iPad. An TouchOSC-interface for the iPad can be found in the repository as well.

![TouchOSC interface](https://github.com/danielbuechele/atemOSC/raw/master/ipad-interface.png)