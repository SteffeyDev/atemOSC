atemOSC v2.0
============

This is a Mac OS X application, providing an interface to control an ATEM video switcher via OSC. 
The code is based on the *SwitcherPanel*-Democode (Version 3.1) provided by Blackmagic. 	Additionally the control of a tally-light interface via Arduino is provided.

![atemOSC](https://github.com/danielbuechele/atemOSC/raw/master/atemOSC.jpg)

- [VVOSC](http://code.google.com/p/vvopensource/) is used as OSC-framework.
- [AMSerialPort](https://github.com/smokyonion/AMSerialPort) is used for Arduino-connection

The current version is built for Mac OS 10.8 SDK. A compiled and runnable version of the atemOSC is included. Caution: The software lacks of many usability features (like input validation).

----------

Program and preview selection as well as transition control are exposed via following OSC addresses:

 - **Cam 1** `/atem/program/1`
 - **Cam 2** `/atem/program/2`
 - **Cam 3** `/atem/program/3`
 - **Cam 4** `/atem/program/4`
 - **Cam 5** `/atem/program/5`
 - **Cam 6** `/atem/program/6`

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
 
All OSC-addresses expect float-values between 0.0 and 1.0.
 
----------

I am using this software with TouchOSC on the iPad. An TouchOSC-interface for the iPad can be found in the repository as well.

![TouchOSC interface](https://github.com/danielbuechele/atemOSC/raw/master/ipad-interface.png)