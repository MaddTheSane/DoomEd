/*
    RDECocoaGlue_View.m

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

#import "RDECocoaGlue_View.h"


@implementation View

- (id) initFrame: (const NSRect *) frameRectPtr
{
    return [super initWithFrame: *frameRectPtr];
}

#pragma mark NSView overrides

- (id) initWithFrame: (NSRect) frameRect
{
    return [self initFrame: &frameRect];
}

- (void) drawRect: (NSRect) rect
{
    RDE_DPSGlue_SetIsDrawingViewRect(YES);

    // outset rect by a 1-pixel margin to account for pixel-centered drawing (centering can
    // offset coordinates by up to 0.5)
    rect = NSInsetRect(NSIntegralRect(rect), -1, -1);

    [self drawSelf: &rect : 1];

    RDE_DPSGlue_SetIsDrawingViewRect(NO);
}

@end

// View methods are implemented as an NSView category so they can also be inherited by
// ScrollView (NSScrollView) & NSScroller

@implementation NSView (RDECocoaGlue_ViewMethods)

- (id) getBounds: (NSRect *) theRect
{
    *theRect = [self bounds];

    return self;
}

- (id) getFrame: (NSRect *) theRect
{
    *theRect = [self frame];

    return self;
}

- (BOOL) getVisibleRect: (NXRect *) theRect
{
    *theRect = [self visibleRect];

    return YES;
}

- (id) setDrawOrigin: (float) x : (float) y
{
    [self setBoundsOrigin: macroRDE_MakeIntegralPoint(x,y)];

    return self;
}

- (id) setDrawSize: (float) width : (float) height
{
    [self setBoundsSize: NSMakeSize(width, height)];

    return self;
}

- (id) convertPointFromSuperview: (NSPoint *) aPoint
{
    *aPoint = [self convertPoint: *aPoint fromView: [self superview]];

    return self;
}

- (id) convertRectFromSuperview: (NSRect *) aRect
{
    *aRect = [self convertRect: *aRect fromView: [self superview]];

    return self;
}

- (id) display: (const NSRect *) rectPtrs : (int) rectCount
{
    while (rectCount > 0)
    {
        [self setNeedsDisplayInRect: *rectPtrs];

        rectPtrs++;
        rectCount--;
    }

    return self;
}

- (id) drawSelf: (const NSRect *) rectPtrs : (int) rectCount
{
    return self;
}

- (id) sizeTo: (float) width : (float) height
{
    [self setFrameSize: NSMakeSize(width, height)];

    return self;
}

- (id) setAutosizing: (unsigned int) mask
{
    [self setAutoresizingMask: mask];

    return self;
}

- (id) printPSCode: (id) sender
{
    [self print: sender];

    return self;
}

@end

