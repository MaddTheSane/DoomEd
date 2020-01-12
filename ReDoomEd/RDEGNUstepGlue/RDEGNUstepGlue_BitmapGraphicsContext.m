/*
    RDEGNUstepGlue_BitmapGraphicsContext.m

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
//  Workaround for GNUstep's missing bitmap graphics-context functionality;
//  Patched MapView (RDEMapExportUtilities) methods, rdeBeginDrawingToBitmapContextOfSize: &
// rdeFinishDrawingToBitmapContextWithReturnedBitmap, to use a focused NSImage instead of a
// bitmap graphics context

#ifdef GNUSTEP

#import <Cocoa/Cocoa.h>
#import "../RDEUtilities/NSObject_PPUtilities.h"
#import "../RDEUtilities/PPAppBootUtilities.h"
#import "../DoomEd/MapView.h"


// restrict max image size to 49 megapixels - larger images were causing crashes (in Cairo)
#define kMaxImageArea   (49000000)

#define macroPresentExportError(...)                                    \
            NSRunAlertPanel(@"Export Error", @"%@", @"OK", nil, nil,    \
                            [NSString stringWithFormat: __VA_ARGS__])


static NSImage *gContextImage = nil;


@implementation NSObject (RDEGNUstepGlue_BitmapGraphicsContext)

+ (void) rdeGSGlue_BitmapGraphicsContext_InstallPatches
{
    macroSwizzleInstanceMethod(MapView, rdeBeginDrawingToBitmapContextOfSize:,
                                rdeGSPatch_rdeBeginDrawingToBitmapContextOfSize:);

    macroSwizzleInstanceMethod(MapView, rdeFinishDrawingToBitmapContextWithReturnedBitmap:,
                                rdeGSPatch_rdeFinishDrawingToBitmapContextWithReturnedBitmap:);
}

+ (void) load
{
    macroPerformNSObjectSelectorAfterAppLoads(rdeGSGlue_BitmapGraphicsContext_InstallPatches);
}

@end

@implementation MapView (RDEGNUstepGlue_BitmapGraphicsContext)

- (bool) rdeGSPatch_rdeBeginDrawingToBitmapContextOfSize: (NSSize) contextSize
{
    if (gContextImage)
        goto ERROR;

    if (((contextSize.width < 1) || (contextSize.height < 1))
        || (contextSize.width * contextSize.height > kMaxImageArea))
    {
        goto ERROR;
    }

NS_DURING // Catch exceptions when contextSize is too large
    gContextImage = [[NSImage alloc] initWithSize: contextSize];
NS_HANDLER
NS_ENDHANDLER

    if (!gContextImage)
        goto ERROR;

    [gContextImage lockFocus];

    return YES;

ERROR:
    macroPresentExportError(@"Failed to allocate Graphics Context Image of size: (%dx%d)",
                            (int) contextSize.width, (int) contextSize.height);

    return NO;
}

- (bool) rdeGSPatch_rdeFinishDrawingToBitmapContextWithReturnedBitmap:
                                                        (NSBitmapImageRep **) returnedBitmap
{
    NSRect contextImageBounds;
    NSBitmapImageRep *bitmap;

    if (!gContextImage)
        goto ERROR;

    // reset the transform to the identity matrix before calling initWithFocusedViewRect:
    // with the image bounds
    [[NSAffineTransform transform] set];

    contextImageBounds.origin = NSZeroPoint;
    contextImageBounds.size = [gContextImage size];    

NS_DURING
    bitmap = nil; // in case next line throws exception
    bitmap = [[NSBitmapImageRep alloc] initWithFocusedViewRect: contextImageBounds];
NS_HANDLER
NS_ENDHANDLER

    [gContextImage unlockFocus];

    [gContextImage release];
    gContextImage = nil;

    if (!bitmap)
    {
        macroPresentExportError(@"Failed to generate Graphics Context Bitmap of size: (%dx%d)",
                                (int) contextImageBounds.size.width,
                                (int) contextImageBounds.size.height);

        goto ERROR;
    }

    *returnedBitmap = bitmap;

    return YES;

ERROR:
    return NO;
}

@end

#endif  // GNUSTEP

