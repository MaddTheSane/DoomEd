/*
    RDEGNUstepGlue_CustomTheme.m

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

//  Customizations to the built-in GNUstep theme (disabled if GNUstep is using a different
// theme, or if RDEDisableGSThemeCustomizations == "YES" in the user defaults):
// - Fix standard GNUstep theme's off-by-one-pixel vertical offsets when drawing text in menu
// items, popup buttons, & tables
// - Make sliders & scrollers more NeXT-like by using checkerboard background pattern
// - Draw all buttons as NeXT-style square buttons
// - Disable focus ring around controls
// - Custom background color for selected text (GNUstep's default is the same color as the
//   window background color, so textfields where the window background shows through would
//   have invisible text selections)

#ifdef GNUSTEP

#import <Cocoa/Cocoa.h>
#import "../RDEUtilities/NSObject_PPUtilities.h"
#import "../RDEUtilities/PPAppBootUtilities.h"
#import "PPGNUstepGlueUtilities.h"
#import "GNUstepGUI/GSTheme.h"


#define kCustomThemeName                                    @"NeoStep"

#define kRDEGSUserDefaultsKey_DisableGSThemeCustomizations  @"RDEDisableGSThemeCustomizations"

// custom selectedTextBackgroundColor must be visible over grey window background and over white
#define kSelectedTextBackgroundColor        [NSColor colorWithCalibratedWhite: 0.8 alpha: 1.0]


static bool ShouldInstallThemeCustomizations(void);
static NSImage *ScrollBarPatternImage(void);


static bool gIsDrawingTableView = NO, gIsDrawingCustomSliderFrame = NO;


@implementation NSObject (RDEGNUstepGlue_CustomTheme)

- (void) rdeGSGlue_CustomTheme_InstallPreBackendPatches
{
    if (!ShouldInstallThemeCustomizations())
    {
        return;
    }

    macroSwizzleClassMethod(NSColor, scrollBarColor, rdeGSPatch_ScrollBarColor);

    macroSwizzleClassMethod(NSColor, selectedTextBackgroundColor,
                            rdeGSPatch_SelectedTextBackgroundColor);
}

+ (void) rdeGSGlue_CustomTheme_InstallPatches
{
    if (!ShouldInstallThemeCustomizations())
    {
        return;
    }

    macroSwizzleInstanceMethod(GSTheme, drawTableViewRect:inView:,
                                rdeGSPatch_DrawTableViewRect:inView:);

    macroSwizzleInstanceMethod(GSTheme, drawButton:in:view:style:state:,
                                rdeGSPatch_DrawButton:in:view:style:state:);

    macroSwizzleInstanceMethod(GSTheme,
                                drawSliderBorderAndBackground:frame:inCell:
                                    isHorizontal:,
                                rdeGSPatch_DrawSliderBorderAndBackground:frame:inCell:
                                    isHorizontal:);

    macroSwizzleInstanceMethod(GSTheme, drawBarInside:inCell:flipped:,
                                rdeGSPatch_DrawBarInside:inCell:flipped:);

    macroSwizzleInstanceMethod(GSTheme, drawFocusFrame:view:, rdeGSPatch_DrawFocusFrame:view:);

    macroSwizzleInstanceMethod(GSTheme, name, rdeGSPatch_Name);


    macroSwizzleInstanceMethod(NSPopUpButtonCell, drawTitleWithFrame:inView:,
                                rdeGSPatch_DrawTitleWithFrame:inView:);


    macroSwizzleInstanceMethod(NSMenuItemCell, drawTitleWithFrame:inView:,
                                rdeGSPatch_DrawTitleWithFrame:inView:);
    
    macroSwizzleInstanceMethod(NSMenuItemCell, drawKeyEquivalentWithFrame:inView:,
                                rdeGSPatch_DrawKeyEquivalentWithFrame:inView:);


    macroSwizzleInstanceMethod(NSTextFieldCell, titleRectForBounds:,
                                rdeGSPatch_TitleRectForBounds:);


    macroSwizzleInstanceMethod(NSSliderCell, drawWithFrame:inView:,
                                rdeGSPatch_DrawWithFrame:inView:);
}

+ (void) load
{
    PPGSGlueUtils_PerformNSUserDefaultsSelectorBeforeGSBackendLoads(
                                @selector(rdeGSGlue_CustomTheme_InstallPreBackendPatches));

    macroPerformNSObjectSelectorAfterAppLoads(rdeGSGlue_CustomTheme_InstallPatches);
}

@end

@implementation NSColor (RDEGNUstepGlue_CustomTheme)

+ (NSColor *) rdeGSPatch_ScrollBarColor
{
    static NSColor *scrollBarPatternColor = nil;

    if (!scrollBarPatternColor)
    {
        NSImage *patternImage = ScrollBarPatternImage();

        scrollBarPatternColor =
            (patternImage) ?
                [NSColor colorWithPatternImage: patternImage] : [self rdeGSPatch_ScrollBarColor];

        [scrollBarPatternColor retain];
    }

    return scrollBarPatternColor;
}

+ (NSColor *) rdeGSPatch_SelectedTextBackgroundColor
{
    static NSColor *selectedTextBackgroundColor = nil;

    if (!selectedTextBackgroundColor)
    {
        selectedTextBackgroundColor = [kSelectedTextBackgroundColor retain];
    }

    return selectedTextBackgroundColor;
}

@end

@implementation GSTheme (RDEGNUStepGlue_CustomTheme)

- (void) rdeGSPatch_DrawTableViewRect: (NSRect) aRect
            inView: (NSView *) view
{
    gIsDrawingTableView = YES;

    [self rdeGSPatch_DrawTableViewRect: aRect inView: view];

    gIsDrawingTableView = NO;
}

// PATCH: -[GSTheme drawButton:in:view:style:state:]
// Draw all buttons as NeXTSTEP-style buttons

- (void) rdeGSPatch_DrawButton: (NSRect)frame
            in: (NSCell*)cell
            view: (NSView*)view
            style: (int)style
            state: (GSThemeControlState)state
{
    [self rdeGSPatch_DrawButton: frame in: cell view: view style: NSNeXTBezelStyle state: state];
}

- (void) rdeGSPatch_DrawSliderBorderAndBackground: (NSBorderType) aType
            frame: (NSRect) cellFrame
            inCell: (NSCell *) cell
            isHorizontal: (BOOL) horizontal
{
    if (gIsDrawingCustomSliderFrame)
        return;

    [self rdeGSPatch_DrawSliderBorderAndBackground: aType
            frame: cellFrame
            inCell: cell
            isHorizontal: horizontal];
}

- (void) rdeGSPatch_DrawBarInside: (NSRect) rect inCell: (NSCell *) cell flipped: (BOOL) flipped
{
    float leftX, rightX, bottomY, topY;
    NSPoint bottomLeftPoint, topLeftPoint, bottomRightPoint, topRightPoint;

    if (!gIsDrawingCustomSliderFrame)
    {
        [self rdeGSPatch_DrawBarInside: rect inCell: cell flipped: flipped];

        return;
    }

    leftX = floorf(NSMinX(rect)) + 0.5f;
    rightX = ceilf(NSMaxX(rect)) - 0.5f;

    if (flipped)
    {
        bottomY = ceilf(NSMaxY(rect)) - 0.5f;
        topY = floorf(NSMinY(rect)) + 0.5f;
    }
    else
    {
        bottomY = floorf(NSMinY(rect)) + 0.5f;
        topY = ceilf(NSMaxY(rect)) - 0.5f;
    }

    // scrollbar fill

    [[NSColor scrollBarColor] set];
    NSRectFill(rect);

    bottomLeftPoint = NSMakePoint(leftX, bottomY);
    bottomRightPoint = NSMakePoint(rightX, bottomY);
    topLeftPoint = NSMakePoint(leftX, topY);
    topRightPoint = NSMakePoint(rightX, topY);

    // highlight bottom & right edges

    [[NSColor whiteColor] set];
    [NSBezierPath strokeLineFromPoint: bottomLeftPoint toPoint: bottomRightPoint];
    [NSBezierPath strokeLineFromPoint: bottomRightPoint toPoint: topRightPoint];

    // darken top & left edges

    [[NSColor controlDarkShadowColor] set];
    [NSBezierPath strokeLineFromPoint: bottomLeftPoint toPoint: topLeftPoint];
    [NSBezierPath strokeLineFromPoint: topLeftPoint toPoint: topRightPoint];
}

// PATCH: -[GSTheme drawFocusFrame:view:]
// Disable all focus rings

- (void) rdeGSPatch_DrawFocusFrame: (NSRect) frame view: (NSView *) view
{
}

- (NSString *) rdeGSPatch_Name
{
    return kCustomThemeName;
}

@end

@implementation NSPopUpButtonCell (RDEGNUstepGlue_CustomTheme)

- (void) rdeGSPatch_DrawTitleWithFrame: (NSRect) cellFrame
            inView: (NSView *) controlView
{
    if ([self controlSize] == NSRegularControlSize)
    {
        cellFrame.origin.y += ([controlView isFlipped]) ? -1 : 1;
    }

    [self rdeGSPatch_DrawTitleWithFrame: cellFrame inView: controlView];
}

@end

@implementation NSMenuItemCell (RDEGNUstepGlue_CustomTheme)

- (void) rdeGSPatch_DrawTitleWithFrame: (NSRect) cellFrame
            inView: (NSView *) controlView
{
    cellFrame.origin.y += ([controlView isFlipped]) ? -1 : 1;

    [self rdeGSPatch_DrawTitleWithFrame: cellFrame inView: controlView];
}

- (void) rdeGSPatch_DrawKeyEquivalentWithFrame: (NSRect) cellFrame
            inView: (NSView *) controlView
{
    cellFrame.origin.y += ([controlView isFlipped]) ? -1 : 1;

    [self rdeGSPatch_DrawKeyEquivalentWithFrame: cellFrame inView: controlView];
}

@end

@implementation NSTextFieldCell (RDEGNUstepGlue_CustomTheme)

- (NSRect) rdeGSPatch_TitleRectForBounds: (NSRect) rect
{
    rect = [self rdeGSPatch_TitleRectForBounds: rect];

    if (gIsDrawingTableView)
    {
        rect.origin.y += ([[self controlView] isFlipped]) ? 1 : -1;
    }

    return rect;
}

@end

@implementation NSSliderCell (RDEGNUstepGlue_CustomTheme)

#define kSliderCellKnobImageName            @"common_SliderHoriz"
#define kSliderCellKnobImageDefaultHeight   14

- (void) rdeGSPatch_DrawWithFrame: (NSRect) cellFrame inView: (NSView *) controlView
{
    static float customSliderFrameHeight = 0;

    if (!customSliderFrameHeight)
    {
        NSImage *knobImage = [NSImage imageNamed: kSliderCellKnobImageName];
        float knobImageHeight =
                (knobImage) ? [knobImage size].height : kSliderCellKnobImageDefaultHeight;

        customSliderFrameHeight = knobImageHeight + 2;
    }

    // only draw custom slider frames on horizontal, non-bezeled slider cells;
    // need to manually compare the cellFrame's width & height to determine if it's horizontal,
    // since -[NSSliderCell isVertical] may return an incorrect value if the slider hasn't
    // been displayed yet
    gIsDrawingCustomSliderFrame =
        ((cellFrame.size.width > cellFrame.size.height) && ![self isBezeled]) ? YES : NO;

    if (gIsDrawingCustomSliderFrame)
    {
        cellFrame.origin.y += roundf((cellFrame.size.height - customSliderFrameHeight) / 2.0f);
        cellFrame.size.height = customSliderFrameHeight;
    }

    [self rdeGSPatch_DrawWithFrame: cellFrame inView: controlView];

    gIsDrawingCustomSliderFrame = NO;
}

@end

#define kGSUserDefaultsKey_ThemeName        @"GSTheme"
#define kStandardGSThemeName                @"GNUstep"
#define kStandardGSThemeNameWithExtension   @"GNUstep.theme"

static bool ShouldInstallThemeCustomizations(void)
{
    NSUserDefaults *userDefaults;
    NSString *currentGSThemeName;
    bool currentGSThemeIsStandardTheme, disallowThemeCustomizations;

    userDefaults = [NSUserDefaults standardUserDefaults];

    currentGSThemeName = [userDefaults stringForKey: kGSUserDefaultsKey_ThemeName];

    currentGSThemeIsStandardTheme =
        (!currentGSThemeName
            || [currentGSThemeName isEqualToString: kStandardGSThemeName]
            || [currentGSThemeName isEqualToString: kStandardGSThemeNameWithExtension])
            ? YES : NO;

    disallowThemeCustomizations =
        ([userDefaults boolForKey: kRDEGSUserDefaultsKey_DisableGSThemeCustomizations])
            ? YES : NO;

    return (currentGSThemeIsStandardTheme && !disallowThemeCustomizations) ? YES : NO;
}

static NSImage *ScrollBarPatternImage(void)
{
    NSImage *patternImage;
    NSColor *patternColor;
    NSRect patternImageBounds = NSZeroRect;

    // 2x2 pattern image (temporary - can't return an image this size because small pattern
    // images slow down drawing, so just used for generating a pattern color that will fill
    // the returned image)

    patternImage = [[[NSImage alloc] initWithSize: NSMakeSize(2,2)] autorelease];

    if (!patternImage)
        goto ERROR;

    [patternImage lockFocus];

    [[NSColor windowBackgroundColor] set];
    NSRectFill(NSMakeRect(0,0,2,2));

    // checkerboard pattern

    [[NSColor controlShadowColor] set];
    NSRectFill(NSMakeRect(0,0,1,1));
    NSRectFill(NSMakeRect(1,1,1,1));

    [patternImage unlockFocus];

    patternColor = [NSColor colorWithPatternImage: patternImage];

    if (!patternColor)
        goto ERROR;

    // returned pattern image (64x64)

    patternImageBounds.size = NSMakeSize(64,64);

    patternImage = [[[NSImage alloc] initWithSize: patternImageBounds.size] autorelease];

    if (!patternImage)
        goto ERROR;

    [patternImage lockFocus];

    [patternColor set];
    NSRectFill(patternImageBounds);

    [patternImage unlockFocus];

    return patternImage;

ERROR:
    return nil;
}

#endif  // GNUSTEP

