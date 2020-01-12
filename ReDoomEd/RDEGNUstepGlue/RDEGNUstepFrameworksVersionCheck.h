/*
    RDEGNUstepFrameworksVersionCheck.h

    Copyright 2019 Josh Freeman
    http://www.twilightedge.com

    This file is part of ReDoomEd for GNUstep. ReDoomEd is a Doom game map editor,
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

#ifdef GNUSTEP

#   define macroCheckGSFrameworkMinAllowedVersion(frameworkName, majorVersion, minorVersion,\
                                                    subminorVersion)                        \
                                                                                            \
            (defined(GNUSTEP_##frameworkName##_MAJOR_VERSION)                               \
            && defined(GNUSTEP_##frameworkName##_MINOR_VERSION)                             \
            && defined(GNUSTEP_##frameworkName##_SUBMINOR_VERSION)                          \
            && ((GNUSTEP_##frameworkName##_MAJOR_VERSION > majorVersion)                    \
                || ((GNUSTEP_##frameworkName##_MAJOR_VERSION == majorVersion)               \
                        && (GNUSTEP_##frameworkName##_MINOR_VERSION > minorVersion))        \
                || ((GNUSTEP_##frameworkName##_MAJOR_VERSION == majorVersion)               \
                        && (GNUSTEP_##frameworkName##_MINOR_VERSION == minorVersion)        \
                        && (GNUSTEP_##frameworkName##_SUBMINOR_VERSION >= subminorVersion))))


//  Required GNUstep framework versions: BASE 1.24.9, GUI 0.25.0

#   if (!macroCheckGSFrameworkMinAllowedVersion(BASE, 1, 24, 9)         \
        || !macroCheckGSFrameworkMinAllowedVersion(GUI, 0, 25, 0))

#       error GNUstep frameworks are too old; \
                ReDoomEd requires GNUstep Base v1.24.9 & GNUstep GUI/Back v0.25.0 (or later)

#   endif   // macroChecks

#endif  // GNUSTEP

