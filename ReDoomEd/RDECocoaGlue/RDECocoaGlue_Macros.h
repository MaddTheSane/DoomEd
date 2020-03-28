/*
    RDECocoaGlue_Macros.h

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

#import <Cocoa/Cocoa.h>


#define macroRDE_SafeCStringCopy(destination, source)                               \
            {                                                                       \
                strncpy(destination, source, sizeof(destination)-1);                \
                destination[sizeof(destination)-1] = 0;                             \
            }


#define macroRDE_ClipCStringLocallyForBufferSize(cString, bufferSize)               \
            {                                                                       \
                if (strlen(cString) >= bufferSize)                                  \
                {                                                                   \
                    cString = (char *) [[NSMutableData dataWithBytes: cString       \
                                                        length: bufferSize]         \
                                                mutableBytes];                      \
                                                                                    \
                    cString[bufferSize-1] = 0;                                      \
                }                                                                   \
            }


#define macroRDE_SizeOfTypeMember(type, member)                                     \
            sizeof(((type *) 0)->member)


// Macros for generating pixel-centered & integral coordinates, points, & rects

#define macroRDE_PixelCenteredCoordinate_Float(x)                                   \
            (floorf(x) + 0.5f)

#define macroRDE_PixelCenteredCoordinate_Double(x)                                  \
            (floor(x) + 0.5)

#define macroRDE_IntegralCoordinate_Float(x)                                        \
            floorf(x)

#define macroRDE_IntegralCoordinate_Double(x)                                       \
            floor(x)


#if !defined(CGFLOAT_IS_DOUBLE) || !CGFLOAT_IS_DOUBLE

#   define macroRDE_PixelCenteredCoordinate_CGFloat                                 \
                macroRDE_PixelCenteredCoordinate_Float

#   define macroRDE_IntegralCoordinate_CGFloat                                      \
                macroRDE_IntegralCoordinate_Float

#else // !defined(CGFLOAT_IS_DOUBLE) || CGFLOAT_IS_DOUBLE

#   define macroRDE_PixelCenteredCoordinate_CGFloat                                 \
                macroRDE_PixelCenteredCoordinate_Double

#   define macroRDE_IntegralCoordinate_CGFloat                                      \
                macroRDE_IntegralCoordinate_Double

#endif


#define macroRDE_MakePixelCenteredPoint(x,y)                                        \
            NSMakePoint(macroRDE_PixelCenteredCoordinate_Float(x),                  \
                        macroRDE_PixelCenteredCoordinate_Float(y))

#define macroRDE_MakePixelCenteredRect(x,y,w,h)                                     \
            NSMakeRect(macroRDE_PixelCenteredCoordinate_Float(x),                   \
                        macroRDE_PixelCenteredCoordinate_Float(y), w, h)

#define macroRDE_PixelCenteredPoint(point)                                          \
            NSMakePoint(macroRDE_PixelCenteredCoordinate_CGFloat((point).x),        \
                        macroRDE_PixelCenteredCoordinate_CGFloat((point).y))

#define macroRDE_PixelCenteredRect(rect)                                            \
            NSMakeRect(macroRDE_PixelCenteredCoordinate_CGFloat((rect).origin.x),   \
                        macroRDE_PixelCenteredCoordinate_CGFloat((rect).origin.y),  \
                        (rect).size.width, (rect).size.height)

#define macroRDE_MakeIntegralPoint(x,y)                                             \
            NSMakePoint(macroRDE_IntegralCoordinate_Float(x),                       \
                        macroRDE_IntegralCoordinate_Float(y))

#define macroRDE_IntegralPoint(point)                                               \
            NSMakePoint(macroRDE_IntegralCoordinate_CGFloat((point).x),             \
                        macroRDE_IntegralCoordinate_CGFloat((point).y))

#if defined(NORDEDEPRECATE) && NORDEDEPRECATE
#define RDE_DEPRECATED_WITH_REPLACEMENT(...) NS_SWIFT_UNAVAILABLE("Very old deprecated API! Don't even think of using it for Swift!")
#define RDE_DEPRECATED(...) NS_SWIFT_UNAVAILABLE("Very old deprecated API! Don't even think of using it for Swift!")
#else
#define RDE_DEPRECATED_WITH_REPLACEMENT(...) API_DEPRECATED_WITH_REPLACEMENT(__VA_ARGS__) NS_SWIFT_UNAVAILABLE("Very old deprecated API! Don't even think of using it for Swift!")
#define RDE_DEPRECATED(...) API_DEPRECATED(__VA_ARGS__) NS_SWIFT_UNAVAILABLE("Very old deprecated API! Don't even think of using it for Swift!")
#endif
