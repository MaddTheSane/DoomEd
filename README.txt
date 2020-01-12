ReDoomEd Sources for Mac OS X & GNUstep
Version 0.92.1 BETA
http://twilightedge.com/mac/redoomed

ABOUT
-----
   ReDoomEd is a Mac/Linux/BSD port of DoomEd, id Software's Doom map editor for NeXTSTEP
workstations.

   DoomEd was developed by John Romero & John Carmack, and used to design the levels of the
original 1990s Doom games. See DoomEd's info page on the Doom Wiki:
https://doomwiki.org/wiki/DoomEd

   DoomEd used a custom text format for its resource files, and relied on a separate
command-line tool, called doombsp, to convert maps from text format to the binary WAD format
used by the Doom engine.

   The levels for the Doom, Ultimate Doom, and Doom II games were publicly released by John
Romero in DoomEd project format (project.dpr) in 2015 [1], and are available for free download
at archive.org [2]. ReDoomEd will open these released project files, however this also requires
a copy of the corresponding game's IWAD file from its retail version (doom.wad, doom2.wad).

   ReDoomEd includes the doombsp tool, and allows a  Doom level to be saved as a patch WAD
file (containing a single map). The saved WAD file can be played using a Doom engine that
supports patching (also requires the corresponding game's IWAD file).

[1] https://www.doomworld.com/vb/post/1363800
[2] https://archive.org/details/2015JohnRomeroDoomDump (doom-maps.zip)


COPYRIGHT
---------
   ReDoomEd uses source-files from DoomEd (map editor), doombsp (command-line tool), and
PikoPixel (pixel-art editor).

   DoomEd & doombsp are copyright (c) 1993, id Software, Inc.

   PikoPixel is copyright (c) 2013-2018, Josh Freeman.

   ReDoomEd-specific source-files and ReDoomEd-specific modifications to
DoomEd/doombsp/PikoPixel source-files (marked by "REDOOMED" compiler-directives) are
copyright (c) 2019, Josh Freeman.


LICENSE
-------
   The sources to DoomEd & doombsp were released publicly by John Romero in 2015 [1], and are
available for free download at archive.org [2]. The license for DoomEd & doombsp is currently
UNKNOWN.

   ReDoomEd source-files, ReDoomEd-specific modifications to DoomEd/doombsp/PikoPixel
source-files, and PikoPixel are released under the terms of the GNU Affero General Public
License as published by the Free Software Foundation. You can redistribute and/or modify them
under the terms of version 3 of the License [3], or (at your option) any later version approved
for distribution by their copyright holder (or an authorized proxy).

[1] https://www.doomworld.com/vb/post/1363790
[2] https://archive.org/details/2015JohnRomeroDoomDump
[3] https://www.gnu.org/licenses/agpl-3.0.en.html


BUILDING ON OS X
----------------
   Building ReDoomEd for Mac OS X requires Xcode 3 or later.

   Open ReDoomEd/ReDoomEd.xcodeproj in Xcode to build & run the application.

   Xcode may warn about updating the project to use Xcode's recommended settings.
ReDoomEd should build successfully with its original project settings, so allowing
Xcode to update the settings is not recommended, as it can cause build issues.

   If you're using Xcode 10 or later (10.14+ SDK), you'll need to switch the
configuration settings file (.xcconfig) for the ReDoomEd project's Debug & Release
build configurations from "RDEXCConfig_10.5sdk" to "RDEXCConfig_10.14sdk"; For
instructions on switching a build configuration's settings file, see the section,
"Map a configuration settings file to a build configuration", in Apple's online Xcode
help:
https://help.apple.com/xcode/mac/current/#/deve97bde215


BUILDING ON GNUSTEP
-------------------
   Building ReDoomEd for GNUstep requires a GNUstep development environment
with either of GNUstep's supported compiler+runtime setups (GCC+gobjc or
clang+objc2), and the following GNUstep library versions (or later):

- GNUstep Base library version 1.24.9
  (released Mar. 20, 2016)

- GNUstep GUI & Back libraries version 0.25.0
  (released Jun. 15, 2016)

   Your distro's repository may contain GNUstep development-environment
packages with the required minimum library versions. For example, on
Ubuntu 16.10+ or Debian 9+, the following set of packages contain all you need
for building ReDoomEd:
build-essential libgnustep-gui-dev gnustep-examples

   More info on installing GNUstep:
http://wiki.gnustep.org/index.php/User_Guides
http://wiki.gnustep.org/index.php/Platform:Linux
http://wiki.gnustep.org/index.php/GNUstep_under_Ubuntu_Linux

   With a compatible GNUstep development environment installed, your shell
environment must be set up to run GNUstep-make; See "4.1 Environment Setup":
http://www.gnustep.org/resources/documentation/User/GNUstep/gnustep-howto_4.html
    
   Once GNUstep-make is set up, ReDoomEd can be built using the following
commands:

cd ReDoomEd
make
sudo -E make install

   After installing, type the following to run ReDoomEd:

openapp ReDoomEd

   ReDoomEd can be added to your desktop environment's menus by copying its
desktop-entry file (found in ReDoomEd.app/Resources) to your desktop
environment's entries directory (usually /usr/share/applications):

sudo desktop-file-install --rebuild-mime-info-cache ReDoomEd.app/Resources/ReDoomEd.desktop

   Once its desktop-entry file is installed, ReDoomEd should appear in your
desktop applications list under 'Development'.
