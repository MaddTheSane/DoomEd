/*
    RDEXCConfigCheck.h

    Copyright 2019 Josh Freeman
    http://www.twilightedge.com

    This file is part of ReDoomEd for Mac OS X and GNUstep. ReDoomEd is a Doom game map
    editor, ported from id Software's DoomEd for NeXTSTEP.

    This file is distributed under the terms of the GNU Affero General Public License
    as published by the Free Software Foundation. You can redistribute it and/or modify
    it under the terms of version 3 of the License, or (at your option) any later
    version approved for distribution by this file's copyright holder (or an authorized
    proxy).

    ReDoomEd is distributed in the hope that it will be useful, but WITHOUT ANY
    WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
    PARTICULAR PURPOSE. See the GNU Affero General Public License for more details.

    You should have received a copy of the GNU Affero General Public License along with
    this program. If not, see <http://www.gnu.org/licenses/>.
*/

// Check that the active Xcode Config File is compatible with the current OS X SDK

#ifdef __APPLE__

#   if _RDE_MAC_OS_X_SDK_VERSION_IS_AT_LEAST_10_(14)

        // Building on 10.14+ SDK: Require RDEXCConfig_10.14sdk.xcconfig

#       ifndef RDEXCCONFIG__10_14_SDK
#           error : To build ReDoomEd with 10.14+ SDKs, you need to use a different Xcode Configuration File; \
Please update the ReDoomEd project's build configuration settings to be based on the .xcconfig file, "RDEXCConfig_10.14sdk".
#       endif

#   else // !_RDE_MAC_OS_X_SDK_VERSION_IS_AT_LEAST_10_(14)

        // Building on 10.5-10.13 SDK: Require RDEXCConfig_10.5sdk.xcconfig

#       ifndef RDEXCCONFIG__10_5_SDK
#           error : To build ReDoomEd with 10.5-10.13 SDKs, you need to use a different Xcode Configuration File; \
Please update the ReDoomEd project's build configuration settings to be based on the .xcconfig file, "RDEXCConfig_10.5sdk".
#       endif

#   endif // !_RDE_MAC_OS_X_SDK_VERSION_IS_AT_LEAST_10_(14)

#endif  // __APPLE__
