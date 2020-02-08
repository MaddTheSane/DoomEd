/*
    RDECocoaGlue_DisplayPostScript.m

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

#import "RDECocoaGlue_DisplayPostScript.h"

#import "../DoomEd/EditWorld.h"
#import "../DoomEd/MapWindow.h"
#import "../DoomEd/MapView.h"


#define kDefaultFont    [NSFont fontWithName: @"Helvetica-Bold" size: 12]

// PSinstroke() tests whether an xy point touches the current path - it's
// used by DoomEd for hit-testing mouseclicks on map lines; for simplicity,
// the ReDoomEd implementation just measures the perpendicular (vertical/
// horizonal) distance to the line, not the actual distance, and uses a
// fudge factor to account for the difference (the max diff is on diagonal
// lines, where the ratio of the perpendicular distance to the actual
// distance is sqrt(2))
#define kPSinstrokePerpendicularDistanceFudgeFactor     1.5

#define kMapLineDisplayWidth_UnscaledOrUpscaled         1.0
#define kMapLineDisplayWidth_Downscaled                 0.85


static NSBezierPath *gCurrentPath = nil, *gInstancePath = nil;
static NSRect gDirtyBoundsOfLastInstance = {{0,0},{0,0}};
static NSColor *gInstancePathColor = nil;
static float gInstancePathLineWidth;
static bool gEnableInstanceDrawing = NO, gIsDrawingViewRect = NO;


static void RedrawFocusViewInBounds(NSRect redrawBounds);
static void SetupInstancePathFromCurrentPath(void);
static void ClearInstancePath(void);
static NSRect DirtyBoundsForInstancePath(void);
static void DrawCurrentPathAsTemporaryInstance(void);
static void RefreshFocusViewAfterInstanceDrawing(void);
static void FrameInstanceRectWithWidth(NSRect rect, float lineWidth);
static float MapLineWidthForCurrentMapViewScale(void);
static void RDE_DPSDoUserPathFloat(const float *coords, int numCoords,
                                   const DPSUserPathOp *ops, int numOps, void *bbox, DPSUserPathAction action);
static void RDE_DPSDoUserPathLong(const short *coords, int numCoords,
                                  const DPSUserPathOp *ops, int numOps, void *bbox, DPSUserPathAction action);
static void RDE_DPSDoUserPathShort(const int *coords, int numCoords,
                                   const DPSUserPathOp *ops, int numOps, void *bbox, DPSUserPathAction action);


#pragma mark RDE substitutes for Display Post Script functions

void RDE_PSsetinstance(BOOL set)
{
    gEnableInstanceDrawing = (set) ? YES : NO;

    gIsDrawingViewRect = NO;

    ClearInstancePath();

    if (gEnableInstanceDrawing)
    {
        [NSGraphicsContext saveGraphicsState];

        PSnewinstance();
    }
    else
    {
        [NSGraphicsContext restoreGraphicsState];

        RefreshFocusViewAfterInstanceDrawing();
    }
}

void RDE_PSnewinstance(void)
{
    gIsDrawingViewRect = NO;

    ClearInstancePath();

    RDE_PSnewpath();
}

void RDE_PSsetrgbcolor(float red, float green, float blue)
{
    NXSetColor(NXConvertRGBToColor(red, green, blue));
}

void RDE_PSsetgray(float gray)
{
    RDE_PSsetrgbcolor(gray, gray, gray);
}

void RDE_PSsetlinewidth(float width)
{
    if (!gCurrentPath)
    {
        gCurrentPath = [NSBezierPath bezierPath];
    }

    if (width < 1)
    {
        // DoomEd only sets line width < 1 when it's drawing mapView lines - if so,
        // use a width value that's tweaked for better visual appearance of scaled
        // maplines
        width = MapLineWidthForCurrentMapViewScale();
    }

    [gCurrentPath setLineWidth: width];

    if (!gIsDrawingViewRect)
    {
        // store the latest non-drawRect line-width value in gInstancePathLineWidth,
        // regardless of instance mode, because -[MapView polyDrag:] sets the line width
        // for its instance before entering instance mode
        gInstancePathLineWidth = width;
    }
}

void RDE_PSselectfont(const char *name, float size)
{
    // DoomEd only calls PSselectfont() with one font, so font is hardcoded into PSshow()
}

void RDE_PSrotate(float angle)
{
    // DoomEd only calls PSrotate() with a zero angle, so do nothing
}

void RDE_PSnewpath(void)
{
    [gCurrentPath removeAllPoints];
}

void RDE_PSmoveto(float x, float y)
{
    if (!gCurrentPath)
    {
        gCurrentPath = [NSBezierPath bezierPath];
    }

    [gCurrentPath moveToPoint: macroRDE_MakePixelCenteredPoint(x, y)];
}

void RDE_PSlineto(float x, float y)
{
    [gCurrentPath lineToPoint: macroRDE_MakePixelCenteredPoint(x, y)];
}

void RDE_PSrlineto(float x, float y)
{
    [gCurrentPath relativeLineToPoint: macroRDE_MakePixelCenteredPoint(x, y)];
}

void RDE_PSclosepath(void)
{
    [gCurrentPath closePath];
}

void RDE_PSstroke(void)
{
    if (gEnableInstanceDrawing)
    {
        DrawCurrentPathAsTemporaryInstance();
    }
    else
    {
        [gCurrentPath stroke];
        [gCurrentPath removeAllPoints];
    }
}

void RDE_PSinstroke(float x, float y, int *pflag)
{
    NSPoint elementPoints[3], lineEndpoint1, lineEndpoint2;
    float lineMinX, lineMinY, lineMaxX, lineMaxY, maxAllowedPerpendicularDistanceForLineHit,
            perpendicularDistanceToLine;
    BOOL pointTouchesLineStroke = NO;

    if (!pflag)
        goto ERROR;

    // DoomEd only calls PSinstroke with paths containing a single line between two points
    if ([gCurrentPath elementCount] != 2)
    {
        goto ERROR;
    }

    [gCurrentPath elementAtIndex: 0 associatedPoints: elementPoints];
    lineEndpoint1 = elementPoints[0];

    [gCurrentPath elementAtIndex: 1 associatedPoints: elementPoints];
    lineEndpoint2 = elementPoints[0];

    if (NSEqualPoints(lineEndpoint1, lineEndpoint2))
    {
        goto ERROR;
    }

    lineMinX = MIN(lineEndpoint1.x, lineEndpoint2.x);
    lineMinY = MIN(lineEndpoint1.y, lineEndpoint2.y);

    lineMaxX = MAX(lineEndpoint1.x, lineEndpoint2.x);
    lineMaxY = MAX(lineEndpoint1.y, lineEndpoint2.y);

    maxAllowedPerpendicularDistanceForLineHit =
                0.5 * [gCurrentPath lineWidth] * kPSinstrokePerpendicularDistanceFudgeFactor;

    perpendicularDistanceToLine = maxAllowedPerpendicularDistanceForLineHit + 1;

    x = macroRDE_PixelCenteredCoordinate_Float(x);
    y = macroRDE_PixelCenteredCoordinate_Float(y);

    if ((lineMaxX - lineMinX) > (lineMaxY - lineMinY))
    {
        // line's more horizontal than vertical - measure vertical distance
        if ((x >= lineMinX)
            && (x <= lineMaxX)
            && (y >= (lineMinY - maxAllowedPerpendicularDistanceForLineHit))
            && (y <= (lineMaxY + maxAllowedPerpendicularDistanceForLineHit)))
        {
            NSPoint lineDiff = NSMakePoint(lineEndpoint2.x - lineEndpoint1.x,
                                            lineEndpoint2.y - lineEndpoint1.y);

            perpendicularDistanceToLine =
                    y - (lineEndpoint1.y + lineDiff.y * ((x - lineEndpoint1.x) / lineDiff.x));
        }
    }
    else
    {
        // line's more vertical than horizontal - measure horizontal distance
        if ((y >= lineMinY)
            && (y <= lineMaxY)
            && (x >= (lineMinX - maxAllowedPerpendicularDistanceForLineHit))
            && (x <= (lineMaxX + maxAllowedPerpendicularDistanceForLineHit)))
        {
            NSPoint lineDiff = NSMakePoint(lineEndpoint2.x - lineEndpoint1.x,
                                            lineEndpoint2.y - lineEndpoint1.y);

            perpendicularDistanceToLine =
                    x - (lineEndpoint1.x + lineDiff.x * ((y - lineEndpoint1.y) / lineDiff.y));
        }
    }

    if (fabsf(perpendicularDistanceToLine) <= maxAllowedPerpendicularDistanceForLineHit)
    {
        pointTouchesLineStroke = YES;
    }

    *pflag = pointTouchesLineStroke;

    return;

ERROR:
    if (pflag)
    {
        *pflag = NO;
    }
}

void RDE_PSshow(char *string)
{
    static NSDictionary *attributes = nil;
    NSString *nsString;

    if (!attributes)
    {
        attributes = [[NSDictionary alloc] initWithObjectsAndKeys:kDefaultFont, NSFontAttributeName, nil];
    }

    nsString = [[NSString alloc] initWithCString: string encoding: NSUTF8StringEncoding];

    [nsString drawAtPoint: macroRDE_IntegralPoint([gCurrentPath currentPoint])
                withAttributes: attributes];

    RDE_PSnewpath();
}

void RDE_PScompositerect(float x, float y, float w, float h, NSCompositingOperation operation)
{
    NSRectFillUsingOperation(macroRDE_MakePixelCenteredRect(x, y, w, h), operation);
}

void RDE_DPSDoUserPath(const void *coords, int numCoords, DPSNumberFormat numType,
                            const DPSUserPathOp *ops, int numOps, void *bbox, DPSUserPathAction action)
{
    switch (numType) {
        case dps_float:
            RDE_DPSDoUserPathFloat(coords, numCoords, ops, numOps, bbox, action);
            break;
            
        case dps_long:
            RDE_DPSDoUserPathLong(coords, numCoords, ops, numOps, bbox, action);
            break;
            
        case dps_short:
            RDE_DPSDoUserPathShort(coords, numCoords, ops, numOps, bbox, action);
            break;
            
        default:
            break;
    }
}

void RDE_DPSDoUserPathFloat(const float *coords, int numCoords,
                            const DPSUserPathOp *ops, int numOps, void *bbox, DPSUserPathAction action)
{
    NSBezierPath *userPath = [NSBezierPath bezierPath];

    while (numOps > 0)
    {
        switch (*ops)
        {
            case dps_moveto:
            {
                [userPath moveToPoint: macroRDE_MakePixelCenteredPoint(coords[0], coords[1])];
                coords += 2;
            }
            break;
                
            case dps_rmoveto:
                [userPath relativeMoveToPoint: macroRDE_MakePixelCenteredPoint(coords[0], coords[1])];
                coords += 2;
                break;

            case dps_lineto:
            {
                [userPath lineToPoint: macroRDE_MakePixelCenteredPoint(coords[0], coords[1])];
                coords += 2;
            }
            break;
                
            case dps_rlineto:
                [userPath relativeLineToPoint: macroRDE_MakePixelCenteredPoint(coords[0], coords[1])];
                coords += 2;
                break;

            case dps_closepath:
            {
                [userPath closePath];
            }
            break;

            case dps_arc:
                [userPath appendBezierPathWithArcWithCenter:macroRDE_MakePixelCenteredPoint(coords[0], coords[1]) radius:coords[2] startAngle:coords[3] endAngle:coords[4] clockwise:true];
                coords += 5;
                break;

            case dps_arcn:
                [userPath appendBezierPathWithArcWithCenter:macroRDE_MakePixelCenteredPoint(coords[0], coords[1]) radius:coords[2] startAngle:coords[3] endAngle:coords[4] clockwise:false];
                coords += 5;
                break;
                
            case dps_arct:
                [userPath appendBezierPathWithArcFromPoint:macroRDE_MakePixelCenteredPoint(coords[0], coords[1]) toPoint:macroRDE_MakePixelCenteredPoint(coords[2], coords[3]) radius:coords[4]];
                coords += 5;
                break;
                
            case dps_curveto:
                [userPath curveToPoint:macroRDE_MakePixelCenteredPoint(coords[0], coords[1]) controlPoint1:macroRDE_MakePixelCenteredPoint(coords[2], coords[3]) controlPoint2:macroRDE_MakePixelCenteredPoint(coords[4], coords[5])];
                coords += 6;
                break;

            case dps_rcurveto:
                [userPath relativeCurveToPoint:macroRDE_MakePixelCenteredPoint(coords[0], coords[1]) controlPoint1:macroRDE_MakePixelCenteredPoint(coords[2], coords[3]) controlPoint2:macroRDE_MakePixelCenteredPoint(coords[4], coords[5])];
                coords += 6;
                break;

            default:
            break;
        }

        ops++;
        numOps--;
    }

    [userPath setLineWidth: [gCurrentPath lineWidth]];

    [userPath stroke];
}

static void RDE_DPSDoUserPathLong(const short *coords, int numCoords,
                                  const DPSUserPathOp *ops, int numOps, void *bbox, DPSUserPathAction action)
{
    NSBezierPath *userPath = [NSBezierPath bezierPath];

    while (numOps > 0)
    {
        switch (*ops)
        {
            case dps_moveto:
            {
                [userPath moveToPoint: macroRDE_MakePixelCenteredPoint(coords[0], coords[1])];
                coords += 2;
            }
            break;
                
            case dps_rmoveto:
                [userPath relativeMoveToPoint: macroRDE_MakePixelCenteredPoint(coords[0], coords[1])];
                coords += 2;
                break;

            case dps_lineto:
            {
                [userPath lineToPoint: macroRDE_MakePixelCenteredPoint(coords[0], coords[1])];
                coords += 2;
            }
            break;
                
            case dps_rlineto:
                [userPath relativeLineToPoint: macroRDE_MakePixelCenteredPoint(coords[0], coords[1])];
                coords += 2;
                break;

            case dps_closepath:
            {
                [userPath closePath];
            }
            break;

            case dps_arc:
                [userPath appendBezierPathWithArcWithCenter:macroRDE_MakePixelCenteredPoint(coords[0], coords[1]) radius:coords[2] startAngle:coords[3] endAngle:coords[4] clockwise:true];
                coords += 5;
                break;

            case dps_arcn:
                [userPath appendBezierPathWithArcWithCenter:macroRDE_MakePixelCenteredPoint(coords[0], coords[1]) radius:coords[2] startAngle:coords[3] endAngle:coords[4] clockwise:false];
                coords += 5;
                break;
                
            case dps_arct:
                [userPath appendBezierPathWithArcFromPoint:macroRDE_MakePixelCenteredPoint(coords[0], coords[1]) toPoint:macroRDE_MakePixelCenteredPoint(coords[2], coords[3]) radius:coords[4]];
                coords += 5;
                break;
                
            case dps_curveto:
                [userPath curveToPoint:macroRDE_MakePixelCenteredPoint(coords[0], coords[1]) controlPoint1:macroRDE_MakePixelCenteredPoint(coords[2], coords[3]) controlPoint2:macroRDE_MakePixelCenteredPoint(coords[4], coords[5])];
                coords += 6;
                break;

            case dps_rcurveto:
                [userPath relativeCurveToPoint:macroRDE_MakePixelCenteredPoint(coords[0], coords[1]) controlPoint1:macroRDE_MakePixelCenteredPoint(coords[2], coords[3]) controlPoint2:macroRDE_MakePixelCenteredPoint(coords[4], coords[5])];
                coords += 6;
                break;

            default:
            break;
        }

        ops++;
        numOps--;
    }

    [userPath setLineWidth: [gCurrentPath lineWidth]];

    [userPath stroke];
}

static void RDE_DPSDoUserPathShort(const int *coords, int numCoords,
                                   const DPSUserPathOp *ops, int numOps, void *bbox, DPSUserPathAction action)
{
    NSBezierPath *userPath = [NSBezierPath bezierPath];

    while (numOps > 0)
    {
        switch (*ops)
        {
            case dps_moveto:
            {
                [userPath moveToPoint: macroRDE_MakePixelCenteredPoint(coords[0], coords[1])];
                coords += 2;
            }
            break;
                
            case dps_rmoveto:
                [userPath relativeMoveToPoint: macroRDE_MakePixelCenteredPoint(coords[0], coords[1])];
                coords += 2;
                break;

            case dps_lineto:
            {
                [userPath lineToPoint: macroRDE_MakePixelCenteredPoint(coords[0], coords[1])];
                coords += 2;
            }
            break;
                
            case dps_rlineto:
                [userPath relativeLineToPoint: macroRDE_MakePixelCenteredPoint(coords[0], coords[1])];
                coords += 2;
                break;

            case dps_closepath:
            {
                [userPath closePath];
            }
            break;

            case dps_arc:
                [userPath appendBezierPathWithArcWithCenter:macroRDE_MakePixelCenteredPoint(coords[0], coords[1]) radius:coords[2] startAngle:coords[3] endAngle:coords[4] clockwise:true];
                coords += 5;
                break;

            case dps_arcn:
                [userPath appendBezierPathWithArcWithCenter:macroRDE_MakePixelCenteredPoint(coords[0], coords[1]) radius:coords[2] startAngle:coords[3] endAngle:coords[4] clockwise:false];
                coords += 5;
                break;
                
            case dps_arct:
                [userPath appendBezierPathWithArcFromPoint:macroRDE_MakePixelCenteredPoint(coords[0], coords[1]) toPoint:macroRDE_MakePixelCenteredPoint(coords[2], coords[3]) radius:coords[4]];
                coords += 5;
                break;
                
            case dps_curveto:
                [userPath curveToPoint:macroRDE_MakePixelCenteredPoint(coords[0], coords[1]) controlPoint1:macroRDE_MakePixelCenteredPoint(coords[2], coords[3]) controlPoint2:macroRDE_MakePixelCenteredPoint(coords[4], coords[5])];
                coords += 6;
                break;

            case dps_rcurveto:
                [userPath relativeCurveToPoint:macroRDE_MakePixelCenteredPoint(coords[0], coords[1]) controlPoint1:macroRDE_MakePixelCenteredPoint(coords[2], coords[3]) controlPoint2:macroRDE_MakePixelCenteredPoint(coords[4], coords[5])];
                coords += 6;
                break;

            default:
            break;
        }

        ops++;
        numOps--;
    }

    [userPath setLineWidth: [gCurrentPath lineWidth]];

    [userPath stroke];
}

#pragma mark DPS Glue functions

void RDE_DPSGlue_DrawInstanceIfNeeded(void)
{
    if (gEnableInstanceDrawing && gInstancePath)
    {
        [gInstancePathColor set];
        [gInstancePath stroke];
    }
}

void RDE_DPSGlue_NXFrameRectWithWidth(NSRect *rectPtr, float frameWidth)
{
    if (gEnableInstanceDrawing)
    {
        // when instance drawing mode is enabled, use PostScript functions to draw the rect -
        // this will store the rect's path in gInstancePath (via gCurrentPath) so it'll be
        // drawn when RDE_DPSGlue_DrawInstanceIfNeeded() is called

        FrameInstanceRectWithWidth(*rectPtr, frameWidth);
    }
    else
    {
        NSFrameRectWithWidth(macroRDE_PixelCenteredRect(*rectPtr), frameWidth);
    }
}

void RDE_DPSGlue_SetNSColor(NSColor *color)
{
    if ([NSGraphicsContext currentContext] != nil)
    {
        [color set];
    }

    if (!gIsDrawingViewRect)
    {
        // store the latest non-drawRect color in gInstancePathColor, regardless of
        // instance mode, because -[MapView polyDrag:] sets the draw color for its
        // instance before entering instance mode
        gInstancePathColor = color;
    }
}

void RDE_DPSGlue_SetIsDrawingViewRect(bool isDrawingViewRect)
{
    gIsDrawingViewRect = (isDrawingViewRect) ? YES : NO;
}

#pragma mark Private functions

static void RedrawFocusViewInBounds(NSRect redrawBounds)
{
    if (NSIsEmptyRect(redrawBounds))
    {
        return;
    }

    [NSGraphicsContext saveGraphicsState];

    [[NSView focusView] setNeedsDisplayInRect: redrawBounds];

    [NSGraphicsContext restoreGraphicsState];
}

static void SetupInstancePathFromCurrentPath(void)
{
    ClearInstancePath();

    if (gCurrentPath && ![gCurrentPath isEmpty])
    {
        gInstancePath = [gCurrentPath copy];

        [gInstancePath setLineWidth: gInstancePathLineWidth];
    }
}

static void ClearInstancePath(void)
{
    if (gInstancePath)
    {
        gInstancePath = nil;
    }
}

static NSRect DirtyBoundsForInstancePath(void)
{
    float pathBoundsOutset;

    if (!gInstancePath || [gInstancePath isEmpty])
    {
        return NSZeroRect;
    }

    pathBoundsOutset = 2.0 * ([gInstancePath lineWidth] + 1.0);

    return NSIntegralRect(
                NSInsetRect([gInstancePath bounds], -pathBoundsOutset, -pathBoundsOutset));
}

static void DrawCurrentPathAsTemporaryInstance(void)
{
    NSRect dirtyBoundsOfCurrentInstance, viewRedrawBounds;

    SetupInstancePathFromCurrentPath();

    dirtyBoundsOfCurrentInstance = DirtyBoundsForInstancePath();
    viewRedrawBounds = NSUnionRect(dirtyBoundsOfCurrentInstance, gDirtyBoundsOfLastInstance);

    RedrawFocusViewInBounds(viewRedrawBounds);

    gDirtyBoundsOfLastInstance = dirtyBoundsOfCurrentInstance;
}

static void RefreshFocusViewAfterInstanceDrawing(void)
{
    RedrawFocusViewInBounds(gDirtyBoundsOfLastInstance);

    gDirtyBoundsOfLastInstance = NSZeroRect;
}

static void FrameInstanceRectWithWidth(NSRect rect, float lineWidth)
{
    float lineHalfWidth, minX, minY, maxX, maxY;

    lineHalfWidth = lineWidth / 2.0;

    if ((rect.size.width <= lineWidth)
        || (rect.size.height <= lineWidth))
    {
        if (rect.size.width < lineWidth)
        {
            rect.origin.x = NSMidX(rect) - lineHalfWidth;
            rect.size.width = lineWidth;
        }

        if (rect.size.height < lineWidth)
        {
            rect.origin.y = NSMidY(rect) - lineHalfWidth;
            rect.size.height = lineWidth;
        }

        lineWidth /= 2.0;
        lineHalfWidth = lineWidth / 2.0;
    }

    minX = NSMinX(rect) + lineHalfWidth;
    maxX = NSMaxX(rect) - lineHalfWidth;
    minY = NSMinY(rect) + lineHalfWidth;
    maxY = NSMaxY(rect) - lineHalfWidth;

    PSnewpath();
    PSsetlinewidth(lineWidth);
    PSmoveto(minX, minY);
    PSlineto(minX, maxY);
    PSlineto(maxX, maxY);
    PSlineto(maxX, minY);
    PSclosepath();

    PSstroke();
}

static float MapLineWidthForCurrentMapViewScale(void)
{
    float mapViewDisplayScale, mapLineDisplayWidth;

    mapViewDisplayScale = [[((MapWindow *) [editworld_i getMainWindow]) mapView] currentScale];

    if (mapViewDisplayScale <= 0)
    {
        mapViewDisplayScale = 1;
    }

    mapLineDisplayWidth = (mapViewDisplayScale >= 1) ? kMapLineDisplayWidth_UnscaledOrUpscaled :
                                                        kMapLineDisplayWidth_Downscaled;

    return mapLineDisplayWidth / mapViewDisplayScale;
}
