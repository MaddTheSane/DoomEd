#import "Storage.h"

#import	"DoomProject.h"
#import "SpecialList.h"
#import	"idfunctions.h"
#import <AppKit/AppKit.h>

@class SectorEditView;
@class FlatsView;

typedef struct flat_s
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
	IBOutlet NSWindow		*window_i;
	IBOutlet SectorEditView	*sectorEditView_i;
	IBOutlet NSScrollView	*flatScrPalView_i;
	IBOutlet FlatsView		*flatPalView_i;
	
	IBOutlet NSTextField	*lightLevel_i;
	IBOutlet NSSlider		*lightSlider_i;
	IBOutlet NSTextField	*special_i;
	IBOutlet NSTextField	*tag_i;
	IBOutlet NSMatrix		*floorAndCeiling_i;		// radio button matrix
	IBOutlet NSButtonCell	*ceiling_i;				// radio button
	IBOutlet NSButtonCell	*floor_i;				// radio button
	IBOutlet NSTextField	*cheightfield_i;
	IBOutlet NSTextField	*fheightfield_i;
	IBOutlet NSTextField	*cflatname_i;
	IBOutlet NSTextField	*fflatname_i;
	IBOutlet NSTextField	*totalHeight_i;
	IBOutlet NSTextField	*curFlat_i;
	
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
@property (readonly) NSInteger countOfFlats;
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

