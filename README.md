# AtemOSC v2.5.3

## Features
This is a macOS application, providing an interface to control an ATEM video switcher via OSC. 

![atemOSC](https://github.com/danielbuechele/atemOSC/raw/master/atemOSC.jpg)

The current version is built for Mac OS 10.13 (as of version 2.5.3). A compiled and runnable version of the atemOSC is included which has been built against Blackmagic SDK 7.4 (as of version 2.5.3). 

## Download the App

1. Go to the [releases page](https://github.com/danielbuechele/atemOSC/releases)
2. For the latest version, use the first release.  For a version that supports older versions of the Atem SDK, scroll down until you find the release for the version you want.
2. Under `Assets`, select `atemOSC.dmg`
3. Double-click the downloaded DMG, drag the application to your Applications folder, then launch it from the Launchpad.

## Setup and Usage

AtemOSC is a proxy, listening for commands following the [OSC protocol](http://opensoundcontrol.org/introduction-osc) and executing those commands on Blackmagic video switchers.  You just have to tell atemOSC where the switcher is and what local port to listen on, and then send commands to the IP address of the computer running atemOSC on port you specified.  If you set an outgoing IP address and port, atemOSC will send status updates and feedback OSC messages to the IP address and port you specified.

**If you are sending atemOSC messages from a queueing software or translation software on the same computer that atemOSC is running on**, make sure to send messages to `127.0.0.1` (localhost) on the port that atemOSC is listening on.

**If you are sending atemOSC messages from another device**, you will need to send it to the IP address of the computer running atemOSC on the port that atemOSC is listening on.  You can find the IP address of a macOS computer by going to `System Preferences` > `Network` or by running `ifconfig` in a terminal window.

----------

## OSC API

 - A full overview of the actual OSC-addresses available for your switcher can be obtained from the help-menu inside the application.
 - Unless otherwise specified, send the value 1 as a float along with the OSC address below. Sending any other value may result in the command not being processed.
 

### Program and Preview Selection

 - **Black** `/atem/program/0`

 - **Cam 1** `/atem/program/1`
 - **Cam 2** `/atem/program/2`
 - **Cam 3** `/atem/program/3`
 - **Cam 4** `/atem/program/4`
 - **Cam 5** `/atem/program/5`
 - **Cam 6** `/atem/program/6`
 - and so on...

 - **Color Bars** `/atem/program/1000`
 - **Color 1** `/atem/program/2001`
 - **Color 2** `/atem/program/2002`
 - **Media 1** `/atem/program/3010`
 - **Media 2** `/atem/program/3020`
 - **Key 1 Mask** `/atem/program/4010`
 - **DSK 1 Mask**: `/atem/program/5010`
 - **DSK 2 Mask**: `/atem/program/5020`
 - **Clean Feed 1** `/atem/program/7001`
 - **Clean Feed 2** `/atem/program/7002`
 - **Auxiliary 1** `/atem/program/8001`
 - and so on...

For preview selection `/atem/preview/$i` can be used.

Feedback: Enabled for all values

Note: The actual numbers vary greatly from device to device, be sure to check the in-app address menu


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
 
 Feedback: None
 
### Auxiliary Source Selection

 - **Set Aux $i source to $x** `/atem/aux/$i $x`
   - Where `$x` is an integer value that is a valid program source, and can be 1-6 depending on the capability of your ATEM switcher. Check the Help Menu for the correct values.
   - e.g. `/atem/aux/1 1` to set Aux 1 output to source 1 (Camera 1)

Feedback: None

### Upstream Keyers

 - **Cut Toggle On-Air Upstream Keyer $i** `/atem/usk/$i` 
 - **Prepare Upstream Keyer $i** `/atem/nextusk/$i`
 - **Set Upstream Keyer $i for Next Scene** `/atem/set-nextusk/$i <0|1>`
     - Send a value of 1 to show the USK after next transition, and 0 if you don’t want to show the USK after next transition
     - e.g. If USK 1 is on air, `/atem/set-nextusk/1 1` will untie USK 1 so that it remains on, while `/atem/set-nextusk/1 0` will tie USK 1 so that it will go off air after the next transition.

Where `$i` can be 1, 2, 3, or 4 depending on the capability of your ATEM switcher

Feedback: Enabled for '/atem/nextusk' only

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

Feedback: Enabled for '/atem/dsk/on-air' and '/atem/dsk/tie' only

### Audio

 - **Change Gain for Audio Input $i** `/atem/audio/input/$i/gain $x`
     - Where `$x` is the gain in decibels (dB), ranging from `-60` to `6`
     - e.g. `/atem/audio/input/2/gain -30.0`
 - **Change Balance for Audio Input $i** `/atem/audio/input/$i/balance $x`
     - Where `$x` is the balance, `-1.0` for full left up to `1.0` for full right
     - e.g. `/atem/audio/input/2/balance 0.4`
 - **Change Gain for Audio Output (Mix)** `/atem/audio/output/gain $x`
     - Where `$x` is the gain in decibels (dB), ranging from `-60` to `6`
     - e.g. `/atem/audio/output/gain -30.0`
 - **Change Balance for Audio Output** `/atem/audio/output/balance $x`
     - Where `$x` is the balance, `-1.0` for full left up to `1.0` for full right
     - e.g. `/atem/audio/output/balance 0.4`

Feedback: Enabled for all values

### Media Players

 - **Set Media Player $i source to Clip $x** `/atem/mplayer/$i/clip/$x`
     - Where `$i` can be 1 or 2, and `$x` can be 1 or 2 depending on the capability of your ATEM switcher
     - e.g. `/atem/mplayer/2/clip/1`
 - **Set Media Player $i source to Still $x** `/atem/mplayer/$i/still/$x`
     - Where `$i` can be 1 or 2, and `$x` can be 1-20 depending on the capability of your ATEM switcher
     - e.g. `/atem/mplayer/1/still/5`

Feedback: None

### SuperSource (when available)

   - **Toggle SuperSource Box $i enabled** `/atem/supersource/$i/enabled <0|1>`
     - Send a value of 1 to enable, and 0 to disable
   - **Set SuperSource Box $i source to input $x** `/atem/supersource/$i/source $x`
     - Where `$x` is a valid program source. Check the Help Menu for the correct values.
   - Other options are available. Check the Help Menu in the app for the full list.

Feedback: None

### Macros

   - Macros should be recorded within the ATEM Control Panel software.
   - Macros are stored within the ATEM in a 0-index array
     - This means that to access the first recorded Macro, you should use an index `$i` of `0`, to access the second recorded Macro, you should use an index of `1` etc.
   - Get the Maximum Number of Macros: `/atem/macros/max-number`
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

Feedback: Enabled for `/atem/macros/max-number`, `/atem/macros/$i/name`, `/atem/macros/$i/description`, and `/atem/macros/$i/is-valid`. Also available On-Request (you can send the command to get the value in a return message)

### Other

  - **Request all feedback available** `/atem/send-status`
  	- This will query the switcher and send back the status for the program/preview, transition control, keyers, and macros
	- e.g. This can be used when a new OSC client device is brought online, so that it gets the current status of the system

----------

## Tested Use Cases

This software has been used successfuly with TouchOSC on the iPad. A TouchOSC-interface for the iPad can be found in the repository.

![TouchOSC interface](https://github.com/danielbuechele/atemOSC/raw/master/ipad-interface.png)

This software has been used successfuly with [ControllerMate](http://www.orderedbytes.com/controllermate/) and [X-keys](http://xkeys.com/XkeysKeyboards/index.php) via [sendOSC](http://archive.cnmat.berkeley.edu/OpenSoundControl/clients/sendOSC.html) and [iTerm 2](https://www.iterm2.com/). An example ActionScript for use within ControllerMate can be found in the repository.  It has also been used with [OSCulator](https://osculator.net).

-----------

## Acknowledgements

- The code is based on the *SwitcherPanel*-Democode (Version 3.5) provided by Blackmagic.
- [VVOSC](http://code.google.com/p/vvopensource/) is used as OSC-framework.
- Program icon based heavily on the ATEM Software Control icon by [Blackmagic Design](http://www.blackmagicdesign.com).
