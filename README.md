# atemOSC v2.4.0

## Changelog v2.4.0
- added support for controlling SuperSource

## Changelog v2.3.5
- added support for setting Aux output source

## Changelog v2.3.4
- added support for specifying transition style
- added more control over downstream keyer states

## Changelog v2.3.3
- added support for controlling Media Players
- updated OSC-addresses help menu to display correct addresses for ATEM 2M/E and above switchers

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

The current version is built for Mac OS 10.9 SDK (as of version 2.2.3). A compiled and runnable version of the atemOSC is included. Caution: The software lacks of many usability features (like input validation).

Program icon based heavily on the ATEM Software Control icon by [Blackmagic Design](http://www.blackmagicdesign.com).

----------

Program and preview selection as well as transition control are exposed via following OSC addresses (addresses given below are for ATEM TVS model, *actual values depend on your ATEM switcher and are shown in the help menu*):

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

To set the transition style of the Auto transition:

 - **Mix** `/atem/transition/set-style/mix`
 - **Dip** `/atem/transition/set-style/dip`
 - **Wipe** `/atem/transition/set-style/wipe`
 - **Stinger** `/atem/transition/set-style/sting`
 - **DVE** `/atem/transition/set-style/dve`

Additional options.

 - **Set Aux $i source to $x** `/atem/aux/$i $x`
   - Where $x is a valid program source. Check the Help Menu for the correct values.
   - e.g. `/atem/aux/1 1` to set Aux 1 output to source 1 (Camera 1)
   - (up to `/atem/aux/6 $x`, depends on your ATEM switcher)
 - **Toggle Upstream Keyer 1** `/atem/usk/1` (up to `/atem/usk/4`, depends on your ATEM switcher)
 - **Prepare Upstream Keyer 1** `/atem/nextusk/1`  (up to `/atem/nextusk/4`, depends on your ATEM switcher)
 - **Auto Toggle Downstreamkeyer 1** `/atem/dsk/1` (up to `/atem/dsk/4`, depends on your ATEM switcher)
 - **Tie Downstreamkeyer 1** `/atem/dsk/tie/1` (up to `/atem/dsk/tie/4`, depends on your ATEM switcher)
 - **Cut Toggle Downstreamkeyer 1** `/atem/dsk/toggle/1` (up to `/atem/dsk/toggle/4`, depends on your ATEM switcher)
 - **Set Media Player $i source to Clip $x** `/atem/mplayer/$i/clip/$x`
   - e.g. `/atem/mplayer/1/clip/1` (up to `/atem/mplayer/1/clip/2`, depends on your ATEM switcher)
   - e.g. `/atem/mplayer/2/clip/1` (up to `/atem/mplayer/2/clip/2`, depends on your ATEM switcher)
 - **Set Media Player $i source to Still $x** `/atem/mplayer/$i/still/$x`
   - e.g. `/atem/mplayer/1/still/1` (up to `/atem/mplayer/1/still/20`, depends on your ATEM switcher)
   - e.g. `/atem/mplayer/2/still/1` (up to `/atem/mplayer/2/still/20`, depends on your ATEM switcher)
 - **SuperSource (when available)**
   - **Toggle SuperSource Box $i enabled** `/atem/supersource/$i/enabled <0|1>`
     - Where `<0|1>` is an int-value of 0 (disabled) or 1 (enabled)
   - **Set SuperSource Box $i source to input $x** `/atem/supersource/$i/source $x`
     - Where `$x` is a valid program source. Check the Help Menu for the correct values.
   - Other options are available. Check the Help Menu for the full list.
 
All OSC-addresses expect float-values between 0.0 and 1.0 unless otherwise stated.

**A full overview of all OSC-addresses available for your switcher can be obtained from the help-menu inside the application.**

----------

I am using this software with TouchOSC on the iPad. An TouchOSC-interface for the iPad can be found in the repository as well.

![TouchOSC interface](https://github.com/danielbuechele/atemOSC/raw/master/ipad-interface.png)
