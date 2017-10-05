# AtemOSC v2.4.7

## Features
This is a macOS application, providing an interface to control an ATEM video switcher via OSC. Additionally, the control of a tally-light interface via Arduino is provided.

![atemOSC](https://github.com/danielbuechele/atemOSC/raw/master/atemOSC.jpg)

The current version is built for Mac OS 10.12 SDK (as of version 2.4.7). A compiled and runnable version of the atemOSC is included. Caution: This software lacks of many usability features (like input validation).

----------

## Download the App

1. Go to the [releases page](https://github.com/danielbuechele/atemOSC/releases)
2. For the latest version, use the first release.  For a version that supports older versions of the Atem SDK, scroll down until you find the release for the version you want.
2. Under `Downloads`, select `Source code (zip)`
3. You will find the atemOSC app inside the downloaded folder.  You can run the app by double-clicking it, or you could move it to your `/Applications` folder and then launch it from the Launchpad.

----------

## OSC API

 - A full overview of the actual OSC-addresses available for your switcher can be obtained from the help-menu inside the application.
 - Unless otherwise specified, send the value 1 as a float along with the OSC address below. Sending any other value may result in the command not being processed.
 

### Program and Preview Selection

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


### Transition Control

 - **T-bar** `/atem/transition/bar <0-1>`
 - **Cut** `/atem/transition/cut`
 - **auto** `/atem/transition/auto`
 - **fade-to-black** `/atem/transition/ftb`

To set the transition type of the Auto transition:

 - **Mix** `/atem/transition/set-type/mix`
 - **Dip** `/atem/transition/set-type/dip`
 - **Wipe** `/atem/transition/set-type/wipe`
 - **Stinger** `/atem/transition/set-type/sting`
 - **DVE** `/atem/transition/set-type/dve`
 
 
### Auxiliary Source Selection

 - **Set Aux $i source to $x** `/atem/aux/$i $x`
   - Where `$x` is a valid program source, and can be 1-6 depending on the capability of your ATEM switcher. Check the Help Menu for the correct values.
   - e.g. `/atem/aux/1 1` to set Aux 1 output to source 1 (Camera 1)
   

### Upstream Keyers

 - **Cut Toggle On-Air Upstream Keyer $i** `/atem/usk/$i` 
 - **Prepare Upstream Keyer $i** `/atem/nextusk/$i`
 - **Set Upstream Keyer $i for Next Scene** `/atem/set-nextusk/$i <0|1>`
     - Send a value of 1 to show the USK after next transition, and 0 if you don’t want to show the USK after next transition
     - e.g. If USK 1 is on air, `/atem/set-nextusk/1 1` will untie USK 1 so that it remains on, while `/atem/set-nextusk/1 0` will tie USK 1 so that it will go off air after the next transition.

Where `$i` can be 1, 2, 3, or 4 depending on the capability of your ATEM switcher
     
     
### Downstream Keyers

 - **Auto Toggle On-Air Downstreamkeyer $i** `/atem/dsk/$i`
 - **Cut Toggle On-Air Downstreamkeyer $i** `/atem/dsk/toggle/$i`
 - **Force On-Air Downstreamkeyer $i** `/atem/dsk/on-air/$i <0|1>`
     - Send a value of 1 to cut the DSK on-air, and a value of 0 to cut it off-air
 - **Toggle Tie Downstreamkeyer $i** `/atem/dsk/tie/$i`
 - **Force Tie Downstreamkeyer $i** `/atem/dsk/set-tie/$i <0|1>`
     - Send a value of 1 to enable tie, and 0 to disable
 - **Set Downstreamkeyer $i for Next Scene** `/atem/dsk/set-next/$i <0|1>`
     - Send a value of 1 to show the DSK after next transition, and 0 if you don’t want to show the DSK after next transition
     - e.g. If DSK1 is on air, `/atem/dsk/set-next/1 1` will untie DSK1 so that it remains on, while `/atem/dsk/set-next/1 0` will tie DSK1 so that it will go off air after the next transition.
 
Where `$i` can be 1, 2, 3, or 4 depending on the capability of your ATEM switcher
 

### Media Players

 - **Set Media Player $i source to Clip $x** `/atem/mplayer/$i/clip/$x`
     - Where `$i` can be 1 or 2, and `$x` can be 1 or 2 depending on the capability of your ATEM switcher
     - e.g. `/atem/mplayer/2/clip/1`
 - **Set Media Player $i source to Still $x** `/atem/mplayer/$i/still/$x`
     - Where `$i` can be 1 or 2, and `$x` can be 1-20 depending on the capability of your ATEM switcher
     - e.g. `/atem/mplayer/1/still/5`
     
   
### SuperSource (when available)

   - **Toggle SuperSource Box $i enabled** `/atem/supersource/$i/enabled <0|1>`
     - Send a value of 1 to enable, and 0 to disable
   - **Set SuperSource Box $i source to input $x** `/atem/supersource/$i/source $x`
     - Where `$x` is a valid program source. Check the Help Menu for the correct values.
   - Other options are available. Check the Help Menu in the app for the full list.
   

### Macros

   - Macros should be recorded within the ATEM Control Panel software.
   - Macros are stored within the ATEM in a 0-index array
     - This means that to access the first recorded Macro, you should use an index `$i` of `0`, to access the second recorded Macro, you should use an index of `1` etc.
   - Get the Maximum Number of Macros: `/atem/macros/get-max-number`
     - Returns an `int` of the maximum number of Macros supported by your ATEM
     - Access to these Macros should be used via an index of `n-1`
   - Stop the currently active Macro (if any): `/atem/macros/stop`
   - Get the Name of a Macro: `/atem/macros/$i/name`
     - Returns a `string` with the name, or "" if the Macro is invalid
   - Get the Description of a Macro: `/atem/macros/$i/description`
     - Returns a `string` with the description, or "" if the Macro is invalid
   - Get whether the Macro at index $i is valid: `/atem/macros/$i/is-valid`
     - Returns an `int` of `0|1` to indicate whether the requested Macro is valid
   - Run the Macro at index $i: `/atem/macros/$i/run`
     - Returns an `int` of `0|1` to indicate whether the requested Macro was executed. A `0` will be returned if the Macro is invalid, or does not exist

----------

## Tested Use Cases

This software has been used successfuly with TouchOSC on the iPad. A TouchOSC-interface for the iPad can be found in the repository.

![TouchOSC interface](https://github.com/danielbuechele/atemOSC/raw/master/ipad-interface.png)

This software has been used successfuly with [ControllerMate](http://www.orderedbytes.com/controllermate/) and [X-keys](http://xkeys.com/XkeysKeyboards/index.php) via [sendOSC](http://archive.cnmat.berkeley.edu/OpenSoundControl/clients/sendOSC.html) and [iTerm 2](https://www.iterm2.com/). An example ActionScript for use within ControllerMate can be found in the repository.  It has also been used with [OSCulator](https://osculator.net).

-----------

## Acknowledgements

- The code is based on the *SwitcherPanel*-Democode (Version 3.5) provided by Blackmagic.
- [VVOSC](http://code.google.com/p/vvopensource/) is used as OSC-framework.
- [AMSerialPort](https://github.com/smokyonion/AMSerialPort) is used for Arduino-connection
- Program icon based heavily on the ATEM Software Control icon by [Blackmagic Design](http://www.blackmagicdesign.com).
