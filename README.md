# AtemOSC v3.1.1

## Features
This is a macOS application, providing an interface to control an ATEM video switcher via OSC.

<img alt="atemOSC Screenshot" src="https://github.com/danielbuechele/atemOSC/raw/master/atemOSC_3.png" width="50%">

The current version is built for Mac OS 10.15.1 (since version 2.5.7). A compiled and runnable version of the atemOSC is included which has been built against Blackmagic SDK 8.1 (since version 2.5.7).

## Download the App

1. Go to the [releases page](https://github.com/danielbuechele/atemOSC/releases)
2. For the latest version, use the first release.  For a version that supports older versions of the Atem SDK, scroll down until you find the release for the version you want.
2. Under `Assets`, select `atemOSC.dmg`
3. Double-click the downloaded DMG, drag the application to your Applications folder, then launch it from the Launchpad.

## Setup and Usage

AtemOSC is a proxy, listening for commands following the [OSC protocol](http://opensoundcontrol.org/introduction-osc) and executing those commands on Blackmagic video switchers.  You just have to tell atemOSC where the switcher is and what local port to listen on, and then send commands to the IP address of the computer running atemOSC on port you specified.  If you set an outgoing IP address and port, atemOSC will send status updates and feedback OSC messages to the IP address and port you specified.

**If you are sending atemOSC messages from a queueing software or translation software on the same computer that atemOSC is running on**, make sure to send messages to `127.0.0.1` (localhost) on the port that atemOSC is listening on.

**If you are sending atemOSC messages from another device**, you will need to send it to the IP address of the computer running atemOSC on the port that atemOSC is listening on.  You can find the IP address of a macOS computer by going to `System Preferences` > `Network` or by running `ifconfig` in a terminal window.

**If you would like to send OSC from AppleScript or Terminal commands**, you can download and use the [sendosc](https://github.com/yoggy/sendosc) command.  See the [actionscript example](https://github.com/danielbuechele/atemOSC/blob/master/samples/controllermate-actionscript.txt) in this repository for an example of using AppleScript and sendOSC.  SendOSC also enables using AtemOSC with [ControllerMate](http://www.orderedbytes.com/controllermate/) and [X-keys](http://xkeys.com/XkeysKeyboards/index.php).

**If you would like to control your switcher using a MIDI board or device**, consider pairing this software with [OSCulator](https://osculator.net) or [MidiPipe](http://www.subtlesoft.square7.net/MidiPipe.html).  If you would like to control AtemOSC directly using MIDI, comment on [Issue #111](https://github.com/danielbuechele/atemOSC/issues/111) to let us know.

**If you would like to control your switcher using a mobile device**, you can use [TouchOSC](https://hexler.net/products/touchosc) (see included layouts in [samples](https://github.com/danielbuechele/atemOSC/tree/master/samples) folder) or Open Stage Control (https://openstagecontrol.ammd.net).

----------

## OSC API

A full overview of the actual OSC-addresses available for your switcher can be obtained from the help menu inside the application.

### Program and Preview Selection

 - **Black** `/atem/program 0`

 - **Cam 1** `/atem/program 1`
 - **Cam 2** `/atem/program 2`
 - **Cam 3** `/atem/program 3`
 - **Cam 4** `/atem/program 4`
 - **Cam 5** `/atem/program 5`
 - **Cam 6** `/atem/program 6`
 - and so on...

 - **Color Bars** `/atem/program 1000`
 - **Color 1** `/atem/program 2001`
 - **Color 2** `/atem/program 2002`
 - **Media 1** `/atem/program 3010`
 - **Media 2** `/atem/program 3020`
 - **Key 1 Mask** `/atem/program 4010`
 - **DSK 1 Mask**: `/atem/program 5010`
 - **DSK 2 Mask**: `/atem/program 5020`
 - **Clean Feed 1** `/atem/program 7001`
 - **Clean Feed 2** `/atem/program 7002`
 - **Auxiliary 1** `/atem/program 8001`
 - and so on...

For preview selection `/atem/preview $i` can be used.

Also supports sending the input in the address instead of as a value (e.g. `/atem/program/5`)

Feedback: Enabled for all values

Note: The actual numbers vary greatly from device to device, be sure to check the in-app address menu

Note: You can fetch the names of each input by sending the `/atem/send-status` command (detailed later), this will return the short names of each input to `/atem/input/$i/short-name` and the long names to `/atem/input/$i/long-name`. After the initial fetch, you will also recieve updates when the short or long name is changed in ATEM Software Control.

### Transition Control

 - **T-bar** `/atem/transition/bar <0-1>`
 - **Cut** `/atem/transition/cut`
 - **Auto** `/atem/transition/auto`
 - **Fade to Black Toggle** `/atem/transition/ftb`
 - **Preview Transition** `/atem/transition/preview <true|false>`

To set the transition type of the Auto transition:

 - **Mix** `/atem/transition/type mix`
 - **Dip** `/atem/transition/type dip`
 - **Wipe** `/atem/transition/type wipe`
 - **Stinger** `/atem/transition/type sting`
 - **DVE** `/atem/transition/type dve`
 - Also supports sending the type in the address instead of as a string value (e.g. `/atem/transition/type/dve`)

 Feedback: None

### Auxiliary Source Selection

 - **Set Aux $i source to $x** `/atem/aux/$i $x`
     - Where `$x` is an integer value that is a valid program source, and can be 1-6 depending on the capability of your ATEM switcher. Check the Help Menu for the correct values.
     - e.g. `/atem/aux/1 1` to set Aux 1 output to source 1 (Camera 1)

Feedback: None

### Upstream Keyers

 - **Set Tie BKGD** `/atem/usk/0/tie <true|false>`
     - Send a value of 1 to enable tie, and 0 to disable
 - **Toggle Tie BKGD** `/atem/usk/0/tie/toggle`
 - **Set On-Air Upstream Keyer $i** `/atem/usk/$i/on-air <true|false>`
     - Send a value of true to cut the USK on-air, and a value of false to cut it off-air
 - **Cut Toggle On-Air Upstream Keyer $i** `/atem/usk/$i/on-air/toggle`
 - **Set Tie Upstream Keyer $i** `/atem/usk/$i/tie <true|false>`
     - Send a value of true to enable tie, and false to disable
 - **Toggle Tie Upstream Keyer $i** `/atem/usk/$i/tie/toggle`
 - **Set Upstream Keyer $i for Next Scene** `/atem/usk/$i/tie/set-next <true|false>`
     - Send a boolean value of true to show the USK after next transition, and false if you don’t want to show the USK after next transition
     - e.g. If USK 1 is on air, `/atem/usk/1/tie/set-next true` will untie USK 1 so that it remains on, while `/atem/usk/1/tie/set-next false` will tie USK 1 so that it will go off air after the next transition.
 - **Set Key type for Upstream Keyer $i** `/atem/usk/$i/type <luma|chroma|pattern|dve>`
     - Also supports sending the type in the address instead of as a string value (e.g. `/atem/usk/$i/type/luma`)

#### USK Source
 - **Set Fill Source for Upstream Keyer $i** `/atem/usk/$i/source/fill <int>`
     - Int value should be the ID of the input to set as the source (from in-app help menu, under the Sources section)
 - **Set Key (cut) Source for Upstream Keyer $i** `/atem/usk/$i/source/cut <int>`
     - Int value should be the ID of the input to set as the source (from in-app help menu, under the Sources section)

#### USK Luma Parameters
 - **Set Clip Luma Parameter for Upstream Keyer $i** `/atem/usk/$i/luma/clip <float>`
     - Float value should be between 0.0 (for 0%) and 1.0 (for 100%)
 - **Set Gain Luma Parameter for Upstream Keyer $i** `/atem/usk/$i/luma/gain <float>`
     - Float value should be between 0.0 (for 0%) and 1.0 (for 100%)
 - **Set Pre-Multiplied Luma Parameter for Upstream Keyer $i** `/atem/usk/$i/luma/pre-multiplied <bool>`
 - **Set Inverse Luma Parameter for Upstream Keyer $i** `/atem/usk/$i/luma/inverse <bool>`

#### USK Chroma Parameters
 - **Set Hue Chroma Parameter for Upstream Keyer $i** `/atem/usk/$i/chroma/hue <float>`
     - Float value should be between 0.0 and 359.9
 - **Set Gain Chroma Parameter for Upstream Keyer $i** `/atem/usk/$i/chroma/gain <float>`
     - Float value should be between 0.0 (for 0%) and 1.0 (for 100%)
 - **Set Y Suppress Chroma Parameter for Upstream Keyer $i** `/atem/usk/$i/chroma/y-suppress <float>`
     - Float value should be between 0.0 (for 0%) and 1.0 (for 100%)
 - **Set Lift Chroma Parameter for Upstream Keyer $i** `/atem/usk/$i/chroma/lift <float>`
     - Float value should be between 0.0 (for 0%) and 1.0 (for 100%)
 - **Set "Narrow Chroma Key Range" Parameter for Upstream Keyer $i** `/atem/usk/$i/chroma/narrow <bool>`

#### USK DVE Parameters
 - **Set DVE Border Enabled for Upstream Keyer $i** `/atem/usk/$i/dve/enabled <true|false>`
 - Other values supported are: `border-width-outer`, `border-width-inner`, `border-softness-outer`, `border-softness-inner`, `border-opacity`, `border-hue`, `border-saturation`, and `border-luma`

Where `$i` can be 1, 2, 3, or 4 depending on the capability of your ATEM switcher

Feedback: Enabled for '/atem/usk/$i/on-air', '/atem/usk/$i/tie', '/atem/usk/$i/source/*', '/atem/usk/$i/luma/*', and '/atem/usk/$i/chroma/*'

### Downstream Keyers

 - **Set On-Air Downstreamkeyer $i** `/atem/dsk/$i/on-air <true|false>`
     - Send a value of true to cut the DSK on-air, and a value of false to cut it off-air
 - **Auto Toggle On-Air Downstreamkeyer $i** `/atem/dsk/$i/on-air/auto`
 - **Cut Toggle On-Air Downstreamkeyer $i** `/atem/dsk/$i/on-air/toggle`
 - **Set Tie Downstreamkeyer $i** `/atem/dsk/$i/tie <true|false>`
     - Send a value of true to enable tie, and false to disable
 - **Toggle Tie Downstreamkeyer $i** `/atem/dsk/$i/tie/toggle`
 - **Set Downstreamkeyer $i for Next Scene** `/atem/dsk/$i/tie/set-next <true|false>`
     - Send a value of true to show the DSK after next transition, and false if you don’t want to show the DSK after next transition
     - e.g. If DSK1 is on air, `/atem/dsk/1/tie/set-next true` will untie DSK1 so that it remains on, while `/atem/dsk/1/tie/set-next false` will tie DSK1 so that it will go off air after the next transition.

#### DSK Source
 - **Set Fill Source for Downstreamkeyer $i** `/atem/dsk/$i/source/fill <int>`
     - Int value should be the ID of the input to set as the source (from in-app help menu, under the Sources section)
 - **Set Key (cut) Source for Downstreamkeyer $i** `/atem/dsk/$i/source/cut <int>`
     - Int value should be the ID of the input to set as the source (from in-app help menu, under the Sources section)

#### DSK Parameters
 - **Set Clip Parameter for Downstreamkeyer $i** `/atem/dsk/$i/clip <float>`
     - Float value should be between 0.0 (for 0%) and 1.0 (for 100%)
 - **Set Gain Parameter for Downstreamkeyer $i** `/atem/dsk/$i/gain <float>`
     - Float value should be between 0.0 (for 0%) and 1.0 (for 100%)
 - **Set Pre-multiplied Parameter for Downstreamkeyer $i** `/atem/dsk/$i/pre-multiplied <true|false>`
 - **Set Invert Parameter for Downstreamkeyer $i** `/atem/dsk/$i/inverse <true|false>`
 - **Set Rate Parameter for Downstreamkeyer $i** `/atem/dsk/$i/rate <int>`
    - Int value is number of frames, so 30 is 1 second and 60 is 2 seconds (given 30 fps base value)

Where `$i` can be 1, 2, 3, or 4 depending on the capability of your ATEM switcher

Feedback: Enabled for '/atem/dsk/$i/on-air' and '/atem/dsk/$i/tie'

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

### Fairlight Audio

 - **Change Gain for Fairlight Audio Source $i** `/atem/fairlight-audio/source/$i/gain $x`
     - Where `$x` is the gain in decibels (dB), ranging from `-60` to `6`
     - e.g. `/atem/fairlight-audio/source/2/gain -30.0`
 - **Change Pan for Fairlight Audio Source $i** `/atem/fairlight-audio/source/$i/pan $x`
     - Where `$x` is the pan, `-1.0` for full left up to `1.0` for full right
     - e.g. `/atem/fairlight-audio/source/2/pan 0.4`
 - **Change Gain for Fairlight Audio Output (Mix)** `/atem/fairlight-audio/output/gain $x`
     - Where `$x` is the gain in decibels (dB), ranging from `-60` to `6`
     - e.g. `/atem/fairlight-audio/output/gain -30.0`

Feedback: Enabled for all values


### Media Players

 - **Set Media Player $i source to Clip $x** `/atem/mplayer/$i/clip $x`
     - Where `$i` can be 1 or 2, and `$x` can be 1 or 2 depending on the capability of your ATEM switcher
     - e.g. `/atem/mplayer/2/clip 1`
 - **Set Media Player $i source to Still $x** `/atem/mplayer/$i/still $x`
     - Where `$i` can be 1 or 2, and `$x` can be 1-20 depending on the capability of your ATEM switcher
     - e.g. `/atem/mplayer/1/still 5`

Feedback: None

### SuperSource (when available)

 - **Toggle SuperSource Box $i enabled** `/atem/supersource/$i/enabled <true|false>`
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

### HyperDeck

 - **Select Clip on HyperDeck $i** `/atem/hyperdeck/$i/clip <int>`
     - e.g. `/atem/hyperdeck/1/clip 5`
 - **Play Selected Clip on HyperDeck $i** `/atem/hyperdeck/$i/play`
 - **Record New Clip on HyperDeck $i** `/atem/hyperdeck/$i/record`
 - **Stop Play/Record on HyperDeck $i** `/atem/hyperdeck/$i/stop`
 - **Shuttle Clip on HyperDeck $i** `/atem/hyperdeck/$i/shuttle $x`
     - Where `$x` is an integer value specifying the speed to start playback at, expressed as a percentage
     - e.g. `/atem/hyperdeck/1/shuttle 200` = 2x speed
     - e.g. `/atem/hyperdeck/1/shuttle 50` = 1/2 speed
     - e.g. `/atem/hyperdeck/1/shuttle 0` = stopped
 - **Jog Clip on HyperDeck $i** `/atem/hyperdeck/$i/jog $x`
     - Where `$x` is an integer value specifying the number of frames to jump forward or backward in the selected clip
 - **Jump to clip time $x on HyperDeck $i** `/atem/hyperdeck/$i/clip-time $x`
     - Where `$x` is a string in the format 'hh:mm:ss' (h = hour, m = minute, s = second)
     - e.g. `/atem/hyperdeck/1/clip-time 00:05:00` = jump 5 minutes into the clip
 - **Jump to timeline time $x on HyperDeck $i** `/atem/hyperdeck/$i/timeline-time $x`

Feedback: Enabled for `/atem/hyperdeck/$i/clip`.  The state of the HyperDeck is available as a string value at `/atem/hyperdeck/$i/state`, and is sent out automatically when the state changes. State options are `play`, `record`, `shuttle`, `idle`, or `unknown`.

### Other

  - **Request all feedback available** `/atem/send-status`
     - This will query the switcher and send back the status for the program/preview, transition control, keyers, and macros
  - e.g. This can be used when a new OSC client device is brought online, so that it gets the current status of the system

### Type Casting

For your convenience, atemOSC will cast certain types to the correct type for certain endpoints

 - If you pass an int or float value of 0 to a boolean method, the 0 will be interpreted as false
 - If you pass an int or float value of 1 to a boolean method, the 1 will be interpreted as true
 - If you pass an int value to an endpoint that requires a float, it will be properly converted (and vice-versa)

### TouchOSC Support

Due to the limited capabilities of the TouchOSC client, atemOSC supports an alternative form of passing values.  For any method listed above that requires a string or int value, you can pass the string or int as part of the address instead of as a value.  For example, you can send `/atem/transition/type/wipe` instead of `/atem/transition/type wipe`, or send `/atem/usk/1/source/fill/3` instead of `/atem/usk/1/source/fill 3`.  Additionally, any command sent with one of these alternative addresses and a float value of `0.0` will be ignored, as that represents a button release and commonly causes issues.  If you would like to trigger a change on button release instead of button press, simply flip the values in the TouchOSC Editor.

----------

## Common Issues

### I want to use \<insert feature here\> that AtemOSC does not support yet

#### Problem

There are a lot of features that AtemOSC does not yet support, most noteably HyperDeck support and advanced USK settings.

#### Solution

You are free to open an issue or comment on and existing issue, but the quickest solution for you is to create a **macro** in ATEM Software Control that accomplishes the task you would like and call the **macro** using AtemOSC.

### Auto and cut commands don’t seem to work, or look buggy, when combining atemOSC with MIDI control

#### Problem
A lot of MIDI controls send two signals when a button is pressed, one signal when you press down, and another when you release. If you connect the button the `/atem/transition/auto` or `cut`, atemOSC recieves both events and attempts to send the transition command to the switcher twice. This can cause buggy behavior or just not work at all.

#### Solution
Tune your MIDI software to send only one of the two signals, either ok button press (rising edge) or button release (falling edge). See #120 for instructions for OSCulator.

-----------

## Acknowledgements

 - The code is based on the *SwitcherPanel*-Democode (Version 3.5) provided by Blackmagic.
 - [VVOSC](http://code.google.com/p/vvopensource/) is used as OSC-framework.
 - Program icon based heavily on the ATEM Software Control icon by [Blackmagic Design](http://www.blackmagicdesign.com).

 ----------

## Developer Resources

### Find what line a crash occured on given a crash report (on MacOS)

People like to send crash reports in issues.  You can use this method to find out which line of the program crashed from just the crash report and version number.

1. Download the `atemOSC.debug.zip` file associated with the release that crashed and unzip it
2. At a command line, `cd` into the unzipped folder (Usually `~/Downloads/atemOSC.debug`)
3. Copy the crash report into a file (e.g. `crash.log`) and save it to the unzipped folder
4. Copy the `find_crash` bash script from the root of this repository into that folder as well
5. Run `./find_crash crash.log`, replacing `crash.log` with whatever your crash report file is named
6. The script should tell you which line in which file caused the crash

