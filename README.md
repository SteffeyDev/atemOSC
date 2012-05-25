atemOSC
=======

This is a Mac OS X application, providing an interface to control an ATEM video switcher via OSC. 
The code is based on the *SwitcherPanel*-Democode (Version 3.1) provided by Blackmagic.

![atemOSC](https://github.com/danielbuechele/atemOSC/raw/master/atemOSC.jpg)


VVOSC is used as OSC-framework.

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

 - **T-bar** `/atem/transition/bar`
 - **Cut** `/atem/transition/cut`
 - **auto** `/atem/transition/auto`
 - **fade-to-black** `/atem/transition/ftb`

----------

I am using this software with TouchOSC on the iPad. An TouchOSC-interface for the iPad can be found in the repository as well.

![TouchOSC interface](https://github.com/danielbuechele/atemOSC/raw/master/ipad-interface.png)