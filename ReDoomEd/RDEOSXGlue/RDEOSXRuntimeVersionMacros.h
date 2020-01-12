/*
    RDEOSXRuntimeVersionMacros.h

    Copyright 2019 Josh Freeman
    http://www.twilightedge.com

    This file is part of ReDoomEd for Mac OS X. ReDoomEd is a Doom game map editor,
    ported from id Software's DoomEd for NeXTSTEP.

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

#ifdef __APPLE__

#import <Foundation/Foundation.h>


#ifndef NSFoundationVersionNumber10_6
#   define NSFoundationVersionNumber10_6    751.00
#endif

#ifndef NSFoundationVersionNumber10_11
#   define NSFoundationVersionNumber10_11   1252.00
#endif

#ifndef NSFoundationVersionNumber10_12
#   define NSFoundationVersionNumber10_12   1300.00
#endif


#   define _RDE_MAC_OS_X_RUNTIME_VERSION_IS_AT_LEAST_10_(DOT_VERSION)                   \
                (NSFoundationVersionNumber >= NSFoundationVersionNumber10_##DOT_VERSION)

#endif  // __APPLE__
