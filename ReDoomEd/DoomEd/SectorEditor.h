// REDOOMED changes (c) 2019 Josh Freeman, distributed under GNU AGPL (v3 or later approved vers.)

#import	"DoomProject.h"
#import	"idfunctions.h"

#ifdef REDOOMED
#   import <Cocoa/Cocoa.h>
#else // Original
#   import <appkit/appkit.h>
#endif

typedef struct
{
	id		image;
	char	name[9];
	NXRect	r;
	int		WADindex;
} flat_t;

#define	SPACING		10
#define	FLATSIZE	64

@class SectorEditor;

extern SectorEditor *sectorEdit_i;

@interface SectorEditor:Object
{
	id	window_i;
	id	sectorEditView_i;
	id	flatScrPalView_i;
	id	flatPalView_i;
	
	id	lightLevel_i;
	id	lightSlider_i;
	id	special_i;
	id	tag_i;
	NSMatrix	*floorAndCeiling_i;		// radio button matrix
	NSButton	*ceiling_i;				// radio button
	NSButton	*floor_i;				// radio button
	id	cheightfield_i;
	id	fheightfield_i;
	id	cflatname_i;
	id	fflatname_i;
	id	totalHeight_i;
	id	curFlat_i;
	
	int	ceiling_flat,floor_flat;
	sectordef_t	sector;
	
	id	flatImages;
	int	currentFlat;
	
	id	specialPanel_i;
}

- setKey:sender;
- setupEditor;
- pgmTarget;
- ceilingAdjust:sender;
- floorAdjust:sender;
- totalHeightAdjust:sender;
- getTagValue:sender;
- lightLevelDown:sender;
- lightLevelUp:sender;
- setSector:(sectordef_t *)s;
- (sectordef_t *) getSector;
- selectFloor;
- selectCeiling;
- lightChanged:sender;
- lightSliderChanged:sender;
- (flat_t *) getCeilingFlat;
- (flat_t *) getFloorFlat;
- setCeiling:(int) what;
- setFloor:(int) what;
- (IBAction)CorFheightChanged:sender;
- (IBAction)locateFlat:sender;
- (int) getNumFlats;
- (char *)flatName:(int) flat;
- (flat_t *) getFlat:(int) which;
- selectFlat:(int) which;
- setCurrentFlat:(int)which;
- (int) getCurrentFlat;
- (IBAction)menuTarget:sender;
- dumpAllFlats;
- emptySpecialList;
- (int)loadFlats;
- computeFlatDocView;
- (int) findFlat:(const char *)name;
- error:(const char *)string;
- saveFrame;

- (IBAction)searchForTaggedSector:sender;
- (IBAction)searchForTaggedLine:sender;

//
// sector special list
//
- (IBAction)activateSpecialList:sender;
- updateSectorSpecialsDSP:(FILE *)stream;
@end

id	flatToImage(byte *rawData, unsigned short *shortpal);
