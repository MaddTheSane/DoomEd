#import "Storage.h"

#import	"DoomProject.h"
#import "SpecialList.h"
#import	"idfunctions.h"
#import <AppKit/AppKit.h>

typedef struct
{
	NSImage	*image;
	char	name[9];
	NSRect	r;
	int		WADindex;
} flat_t;

#define	SPACING		10
#define	FLATSIZE	64

@interface SectorEditor:NSObject <SpecialListDelegate, NSWindowDelegate>
{
	IBOutlet NSWindow	*window_i;
	IBOutlet id	sectorEditView_i;
	IBOutlet NSScrollView	*flatScrPalView_i;
	IBOutlet id	flatPalView_i;
	
	IBOutlet id	lightLevel_i;
	IBOutlet id	lightSlider_i;
	IBOutlet id	special_i;
	IBOutlet id	tag_i;
	IBOutlet NSMatrix	*floorAndCeiling_i;		// radio button matrix
	IBOutlet NSButtonCell	*ceiling_i;				// radio button
	IBOutlet NSButtonCell	*floor_i;				// radio button
	IBOutlet id	cheightfield_i;
	IBOutlet id	fheightfield_i;
	IBOutlet id	cflatname_i;
	IBOutlet id	fflatname_i;
	IBOutlet id	totalHeight_i;
	IBOutlet id	curFlat_i;
	
	int	ceiling_flat,floor_flat;
	sectordef_t	sector;
	
	CompatibleStorage *flatImages;
	int	currentFlat;
	
	SpecialList *specialPanel_i;
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
- (int) getNumFlats;
- (NSString *) flatName: (int) flat;
- (flat_t *) getFlat:(int) which;
- (void)selectFlat:(int) which;
- (void)setCurrentFlat:(int)which;
- (int) getCurrentFlat;
- (IBAction)menuTarget:sender;
- (void)dumpAllFlats;
- (void)emptySpecialList;
- (int)loadFlats;
- (void)computeFlatDocView;
- (int) findFlat:(const char *)name;
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

extern SectorEditor *sectorEdit_i;

NSImage *flatToImage(byte *rawData, unsigned short *shortpal);

