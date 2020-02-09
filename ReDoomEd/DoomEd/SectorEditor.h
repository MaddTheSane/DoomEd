// REDOOMED changes (c) 2019 Josh Freeman, distributed under GNU AGPL (v3 or later approved vers.)

#import	"DoomProject.h"
#import	"idfunctions.h"
#import "SpecialList.h"

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
@class SpecialList;
@class Storage;
@class FlatsView;
@class SectorEditView;

extern SectorEditor *sectorEdit_i;

@interface SectorEditor:NSObject <SpecialList>
{
	IBOutlet NSPanel		*window_i;
	IBOutlet SectorEditView	*sectorEditView_i;
	IBOutlet NSScrollView	*flatScrPalView_i;
	IBOutlet FlatsView		*flatPalView_i;
	
	IBOutlet NSTextField	*lightLevel_i;
	IBOutlet NSSlider		*lightSlider_i;
	IBOutlet NSTextField	*special_i;
	IBOutlet NSTextField	*tag_i;
	IBOutlet NSMatrix		*floorAndCeiling_i;		// radio button matrix
	IBOutlet NSButton		*ceiling_i;				// radio button
	IBOutlet NSButton		*floor_i;				// radio button
	IBOutlet NSTextField	*cheightfield_i;
	IBOutlet NSTextField	*fheightfield_i;
	IBOutlet NSTextField	*cflatname_i;
	IBOutlet NSTextField	*fflatname_i;
	IBOutlet NSTextField	*totalHeight_i;
	IBOutlet NSTextField	*curFlat_i;
	
	int	ceiling_flat,floor_flat;
	sectordef_t	sector;
	
	Storage	*flatImages;
	NSInteger	currentFlat;
	
	SpecialList	*specialPanel_i;
}

- (IBAction)setKey:sender;
- (void)setupEditor;
- (void)pgmTarget;
- (IBAction)ceilingAdjust:sender;
- (IBAction)floorAdjust:sender;
- (IBAction)totalHeightAdjust:sender;
- (IBAction)getTagValue:sender;
- (IBAction)lightLevelDown:sender;
- (IBAction)lightLevelUp:sender;
- (void)setSector:(sectordef_t *)s;
- (sectordef_t *) getSector;
- (void)selectFloor;
- (void)selectCeiling;
- (IBAction)lightChanged:sender;
- (IBAction)lightSliderChanged:sender;
- (flat_t *) getCeilingFlat;
- (flat_t *) getFloorFlat;
- (void)setCeiling:(int) what;
- (void)setFloor:(int) what;
- (IBAction)CorFheightChanged:sender;
- (IBAction)locateFlat:sender;
@property (readonly) NSInteger countOfFlats;
- (const char *)flatName:(NSInteger) flat;
- (flat_t *) getFlat:(NSInteger) which;
- (void)selectFlat:(NSInteger) which;
@property (nonatomic) NSInteger currentFlat;
- (IBAction)menuTarget:sender;
- (void)dumpAllFlats;
- (void)emptySpecialList;
- (int)loadFlats;
- (void)computeFlatDocView;
- (NSInteger) findFlat:(const char *)name;
- (void)error:(const char *)string;
- (void)saveFrame;

- (IBAction)searchForTaggedSector:sender;
- (IBAction)searchForTaggedLine:sender;

//
// sector special list
//
- (IBAction)activateSpecialList:sender;
- (void)updateSectorSpecialsDSP:(FILE *)stream;
@end

/// Convert a raw 64x64 to an \c NXImage without an alpha channel
NSImage *flatToImage(byte *rawData, unsigned short *shortpal) NS_RETURNS_RETAINED;
