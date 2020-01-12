/*
    RDEMapExport.m

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

#import "RDEMapExport.h"

#import "DoomEd/EditWorld.h"
#import "DoomEd/MapWindow.h"
#import "DoomEd/MapView.h"
#import "RDEUtilities/PPSRGBUtilities.h"


#define macroPresentExportError(...)                                    \
            NSRunAlertPanel(@"Export Error", @"%@", @"OK", nil, nil,    \
                            [NSString stringWithFormat: __VA_ARGS__])


typedef enum
{
    kRDEExportMode_DrawingMapImage,
    kRDEExportMode_ConvertingToPNG,
    kRDEExportMode_SavingFile,

    kNumRDEExportModes

} RDEExportMode;

typedef struct
{
    int numExportedMaps;
    int maxThermoValue;
    int indexedBaseThermoValue;
    NSString *messagePrefix;

} RDEExportThermoPanelState;


static RDEExportThermoPanelState gThermoPanelState;
static NSBitmapImageRep *gMapViewBitmap;


@interface DoomProject (RDEMapExportUtilities)

- (bool) rdeHandleMapDirtyBeforeExportAll;

- (bool) rdeVerifyExportDirectory: (NSString *) exportDirectoryPath;

- (void) rdeDisplayMapAtIndex: (int) mapIndex;

- (void) rdeSetupExportThermoPanelWithNumExportedMaps: (int) numExportedMaps
                                            andScale: (float) scale;
- (void) rdeUpdateExportThermoPanelWithMapName: (NSString *) mapName forIndex: (int) mapIndex;
- (void) rdeUpdateExportThermoPanelWithExportMode: (RDEExportMode) exportMode;
- (void) rdeFinishExportThermoPanel;

@end

@interface MapView (RDEMapExportUtilities)

+ (MapView *) rdeCurrentMapView;

- (NSData *) rdePNGDataAtScale: (float) pngScale;

- (bool) rdeBeginDrawingToBitmapContextOfSize: (NSSize) contextSize;
- (bool) rdeFinishDrawingToBitmapContextWithReturnedBitmap: (NSBitmapImageRep **) returnedBitmap;

@end

@implementation DoomProject (RDEMapExport)

- (void) rdeExportMapAsPNG
{
    MapView *mapView;
    NSString *mapName, *pngFilename;
    NSSavePanel *savePanel;
    NSInteger panelReturnCode;
    float pngScale;
    NSData *pngData;

    mapView = [MapView rdeCurrentMapView];

    if (!mapView)
        goto ERROR;

    mapName = [[[maps_i matrixInColumn: 0] selectedCell] stringValue];

    if (![mapName length])
    {
        goto ERROR;
    }

    pngFilename = [mapName stringByAppendingPathExtension: @"png"];

    savePanel = [NSSavePanel savePanel];
    [savePanel setAllowedFileTypes: [NSArray arrayWithObject: @"png"]];

    panelReturnCode = [savePanel runModalForDirectory: nil file: pngFilename];

    if (panelReturnCode != NSFileHandlingPanelOKButton)
    {
        return;
    }

    pngScale = [mapView currentScale];

    if (pngScale <= 0)
    {
        pngScale = 1;
    }

    [self rdeSetupExportThermoPanelWithNumExportedMaps: 1 andScale: pngScale];
    [self rdeUpdateExportThermoPanelWithMapName: mapName forIndex: 0];

    pngData = [mapView rdePNGDataAtScale: pngScale];

    if (!pngData)
        goto ERROR;

    [self rdeUpdateExportThermoPanelWithExportMode: kRDEExportMode_SavingFile];

    if (![pngData writeToFile: [savePanel filename] atomically: YES])
    {
        macroPresentExportError(@"Failed to write file:\n%@", [savePanel filename]);
        goto ERROR;
    }

    [self rdeFinishExportThermoPanel];

    return;

ERROR:
    [self rdeFinishExportThermoPanel];

    return;
}

- (void) rdeExportAllMapsAsPNG
{
    float pngScale;
    NSOpenPanel *openPanel;
    NSInteger panelReturnCode;
    NSString *exportDirectory, *pngFilepath, *mapName, *pngFilename;
    NSMatrix *mapNameMatrix;
    NSInteger indexOfInitiallyVisibleMap;
    int mapIndex;
    NSAutoreleasePool *autoreleasePool;
    NSData *pngData;
    bool redisplayInitialMapOnError = NO;

    if (!loaded || (nummaps <= 0))
    {
        goto ERROR;
    }

    if (mapdirty && ![self rdeHandleMapDirtyBeforeExportAll])
    {
        return;
    }

    pngScale = [[MapView rdeCurrentMapView] currentScale];

    if (pngScale <= 0)
    {
        pngScale = 1;
    }

    openPanel = [NSOpenPanel openPanel];
    [openPanel setTitle: @"Choose save directory for exported map images"];
    [openPanel setAllowedFileTypes: nil];
    [openPanel setCanChooseDirectories: YES];
    [openPanel setCanCreateDirectories: YES];
    [openPanel setAllowsMultipleSelection: NO];

    panelReturnCode = [openPanel runModal];

    if (panelReturnCode != NSFileHandlingPanelOKButton)
    {
        return;
    }

    exportDirectory = [openPanel filename];

    if (![self rdeVerifyExportDirectory: exportDirectory])
    {
        goto ERROR;
    }

    mapNameMatrix = [maps_i matrixInColumn: 0];

    indexOfInitiallyVisibleMap = [mapNameMatrix selectedRow];

    [self rdeSetupExportThermoPanelWithNumExportedMaps: nummaps andScale: pngScale];

    for (mapIndex=0; mapIndex<nummaps; mapIndex++)
    {
        autoreleasePool = [[NSAutoreleasePool alloc] init];

        mapName = [[mapNameMatrix cellAtRow: mapIndex column: 0] stringValue];

        if (![mapName length])
        {
            [autoreleasePool release];
            continue;
        }

        [mapNameMatrix selectCellAtRow: mapIndex column: 0];
		[self openMap: mapNameMatrix];
        redisplayInitialMapOnError = YES;

        [self rdeUpdateExportThermoPanelWithMapName: mapName forIndex: mapIndex];

        pngFilename = [mapName stringByAppendingPathExtension: @"png"];

        pngData = [[MapView rdeCurrentMapView] rdePNGDataAtScale: pngScale];

        if (!pngData)
        {
            [autoreleasePool release];
            goto ERROR;
        }

        [self rdeUpdateExportThermoPanelWithExportMode: kRDEExportMode_SavingFile];

        pngFilepath = [exportDirectory stringByAppendingPathComponent: pngFilename];

        if (![pngData writeToFile: pngFilepath atomically: YES])
        {
            macroPresentExportError(@"Failed to write file:\n%@", pngFilepath);
            [autoreleasePool release];
            goto ERROR;
        }

        [autoreleasePool release];
    }

    [self rdeFinishExportThermoPanel];

    [self rdeDisplayMapAtIndex: indexOfInitiallyVisibleMap];

    return;

ERROR:
    [self rdeFinishExportThermoPanel];

    if (redisplayInitialMapOnError)
    {
        [self rdeDisplayMapAtIndex: indexOfInitiallyVisibleMap];
    }
}

@end

@implementation DoomProject (RDEMapExportUtilities)

- (bool) rdeHandleMapDirtyBeforeExportAll
{
    NSInteger panelReturnCode;
    
    if (!mapdirty)
    {
        return YES;
    }
    
    panelReturnCode =
        NSRunAlertPanel(@"Export All: Save modified map?",
                        @"The current map has unsaved changes. When exporting all maps, "
                        "unsaved changes will be lost unless the map is saved first.",
                        @"Cancel Export", @"Save Map & Export", @"Lose Changes & Export");

    if (panelReturnCode == NSAlertAlternateReturn) // Save Changes
    {
        [editworld_i saveWorld: nil];
    }
    else if (panelReturnCode == NSAlertOtherReturn) // Lose Changes
    {
        [self setDirtyMap: FALSE];
    }
    else // Cancel Export
    {
        return NO;
    }
 
    return YES;
}

- (bool) rdeVerifyExportDirectory: (NSString *) exportDirectory
{
    NSFileManager *fileManager;
    NSMatrix *mapNameMatrix;
    int mapIndex;
    NSString *mapName, *pngFilename, *pngFilepath;
    BOOL isDirectory;

    if (!exportDirectory)
        goto ERROR;

    fileManager = [NSFileManager defaultManager];

    if (![fileManager fileExistsAtPath: exportDirectory isDirectory: &isDirectory]
        || !isDirectory
        || ![fileManager isWritableFileAtPath: exportDirectory])
    {
        goto ERROR;
    }

    mapNameMatrix = [maps_i matrixInColumn: 0];

    for (mapIndex=0; mapIndex<nummaps; mapIndex++)
    {
        mapName = [[mapNameMatrix cellAtRow: mapIndex column: 0] stringValue];

        if (![mapName length])
        {
            continue;
        }

        pngFilename = [mapName stringByAppendingPathExtension: @"png"];
        pngFilepath = [exportDirectory stringByAppendingPathComponent: pngFilename];

        if ([fileManager fileExistsAtPath: pngFilepath])
        {
            NSInteger alertReturnCode =
                            NSRunAlertPanel(@"Replace existing map images?",
                                            @"Exported map images already exist in \"%@\".\n\n"
                                            "Do you want to replace them?\n",
                                            @"Cancel", @"Replace", nil, exportDirectory);

            return (alertReturnCode == NSAlertAlternateReturn) ? YES : NO;
        }
    }

    return YES;

ERROR:
    return NO;
}

- (void) rdeDisplayMapAtIndex: (int) mapIndex
{
    NSMatrix *mapNameMatrix = [maps_i matrixInColumn: 0];

	if ((mapIndex >= 0) && (mapIndex < nummaps))
	{
        [mapNameMatrix selectCellAtRow: mapIndex column: 0];
		[self openMap: mapNameMatrix];
	}
    else
    {
        [mapNameMatrix deselectSelectedCell];
        [editworld_i closeWorld];
    }
}

- (void) rdeSetupExportThermoPanelWithNumExportedMaps: (int) numExportedMaps
                                            andScale: (float) scale
{
    int scalePercent;
    NSString *title;

    gThermoPanelState.numExportedMaps = numExportedMaps;
    gThermoPanelState.maxThermoValue = numExportedMaps * kNumRDEExportModes;
    gThermoPanelState.indexedBaseThermoValue = 0;

    [gThermoPanelState.messagePrefix release];
    gThermoPanelState.messagePrefix = nil;

    scalePercent = (int) roundf(scale * 100.0f);

    title = [NSString stringWithFormat: @"Exporting %@ (scale: %d%%)",
                                        (numExportedMaps > 1) ? @"maps" : @"map",
                                        scalePercent];

    [self initThermo: (char *) RDE_CStringFromNSString(title) message: ""];
}

- (void) rdeUpdateExportThermoPanelWithMapName: (NSString *) mapName forIndex: (int) mapIndex
{
    NSString *message;

    message = [NSString stringWithFormat: @"Map \"%@\"", mapName];

    if (gThermoPanelState.numExportedMaps > 1)
    {
        message = [message stringByAppendingFormat: @" (%d of %d)", mapIndex + 1,
                                                    gThermoPanelState.numExportedMaps];
    }

    message = [message stringByAppendingString: @": "];

    [gThermoPanelState.messagePrefix release];
    gThermoPanelState.messagePrefix = [message retain];

    gThermoPanelState.indexedBaseThermoValue = mapIndex * kNumRDEExportModes;

    [self rdeUpdateExportThermoPanelWithExportMode: 0];
}

- (void) rdeUpdateExportThermoPanelWithExportMode: (RDEExportMode) exportMode
{
    NSString *modeName, *message;

    switch (exportMode)
    {
        case kRDEExportMode_DrawingMapImage:
        {
            modeName = @"Drawing map image...";
        }
        break;

        case kRDEExportMode_ConvertingToPNG:
        {
            modeName = @"Converting to PNG... ";
        }
        break;

        case kRDEExportMode_SavingFile:
        {
            modeName = @"Writing PNG file...    ";
        }
        break;

        default:
        {
            modeName = @"";
        }
        break;
    }

    message = [gThermoPanelState.messagePrefix stringByAppendingString: modeName];

    [thermoMsg_i setStringValue: message];
    [thermoMsg_i display];

    [self updateThermo: gThermoPanelState.indexedBaseThermoValue + exportMode
            max: gThermoPanelState.maxThermoValue];

	[thermoWindow_i	makeKeyAndOrderFront: nil];
}

- (void) rdeFinishExportThermoPanel
{
    [self closeThermo];

    [gThermoPanelState.messagePrefix release];
    gThermoPanelState.messagePrefix = nil;
}

@end

@implementation MapView (RDEMapExportUtilities)

+ (MapView *) rdeCurrentMapView
{
    return [((MapWindow *) [editworld_i getMainWindow]) mapView];
}

- (NSData *) rdePNGDataAtScale: (float) pngScale
{
    static NSDictionary *pngProperties = nil;
    NSRect mapBounds;
    NSSize pngImageSize;
    NSAffineTransform *transform;
    NSBitmapImageRep *bitmap;
    NSData *pngData;

    if (!pngProperties)
    {
        pngProperties = [[NSDictionary dictionary] retain];
    }

    if (pngScale <= 0)
    {
        pngScale = 1;
    }

    [editworld_i getBounds: &mapBounds];

    if (NSIsEmptyRect(mapBounds))
    {
        goto ERROR;
    }

    pngImageSize = NSMakeSize(MAX(round(mapBounds.size.width * pngScale), 1.0),
                                MAX(round(mapBounds.size.height * pngScale), 1.0));

    if (![self rdeBeginDrawingToBitmapContextOfSize: pngImageSize])
    {
        goto ERROR;
    }

    transform = [NSAffineTransform transform];

    [transform translateXBy: -mapBounds.origin.x yBy: -mapBounds.origin.y];

    if (!NSEqualSizes(pngImageSize, mapBounds.size))
    {
        NSAffineTransform *scaleTransform = [NSAffineTransform transform];

        [scaleTransform scaleXBy: pngImageSize.width / mapBounds.size.width
                        yBy: pngImageSize.height / mapBounds.size.height];

        [transform appendTransform: scaleTransform];
    }

    [transform set];

    [self drawRect: mapBounds];

    if (![self rdeFinishDrawingToBitmapContextWithReturnedBitmap: &bitmap])
    {
        goto ERROR;
    }

    [doomproject_i rdeUpdateExportThermoPanelWithExportMode: kRDEExportMode_ConvertingToPNG];

NS_DURING
    pngData = nil; // in case next line throws exception
    pngData = [bitmap representationUsingType: NSPNGFileType properties: pngProperties];
NS_HANDLER
NS_ENDHANDLER

    if (!pngData)
    {
        macroPresentExportError(@"Failed to generate PNG image data for bitmap of size: (%dx%d)",
                                (int) [bitmap pixelsWide],
                                (int) [bitmap pixelsHigh]);

        goto ERROR;
    }

    return pngData;

ERROR:
    return nil;
}

- (bool) rdeBeginDrawingToBitmapContextOfSize: (NSSize) contextSize
{
    NSBitmapImageRep *bitmap;
    NSGraphicsContext *bitmapContext = nil;

    if ((contextSize.width < 1) || (contextSize.height < 1))
    {
        goto ERROR;
    }

NS_DURING // Catch NSImage exceptions when contextSize is too large
    bitmap = [[[NSBitmapImageRep alloc] initWithBitmapDataPlanes: NULL
                                            pixelsWide: contextSize.width
                                            pixelsHigh: contextSize.height
                                            bitsPerSample: 8
                                            samplesPerPixel: 4
                                            hasAlpha: YES
                                            isPlanar: NO
                                            colorSpaceName: NSCalibratedRGBColorSpace
                                            bytesPerRow: 0
                                            bitsPerPixel: 0]
                                    autorelease];

    if (bitmap)
    {
        [bitmap ppAttachSRGBColorProfile];

        bitmapContext = [NSGraphicsContext graphicsContextWithBitmapImageRep: bitmap];
    }
NS_HANDLER
NS_ENDHANDLER

    if (!bitmapContext)
        goto ERROR;

    [NSGraphicsContext saveGraphicsState];
    [NSGraphicsContext setCurrentContext: bitmapContext];

    // store the bitmap in a global because OS X's NSGraphicsContext was returning a nil
    // attributes dict (context's bitmap should be in the attributes dict)
    [gMapViewBitmap release];
    gMapViewBitmap = [bitmap retain];

    return YES;

ERROR:
    macroPresentExportError(@"Failed to allocate Graphics Context of size: (%dx%d)",
                            (int) contextSize.width, (int) contextSize.height);

    return NO;
}

- (bool) rdeFinishDrawingToBitmapContextWithReturnedBitmap: (NSBitmapImageRep **) returnedBitmap
{
    NSBitmapImageRep *bitmap;

    [NSGraphicsContext restoreGraphicsState];

    if (!gMapViewBitmap)
        goto ERROR;

    bitmap = [[gMapViewBitmap retain] autorelease];

    [gMapViewBitmap release];
    gMapViewBitmap = nil;

    if (!returnedBitmap)
        goto ERROR;

    *returnedBitmap = bitmap;

    return YES;

ERROR:
    return NO;
}

@end