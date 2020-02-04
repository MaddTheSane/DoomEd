#import "EditWorld.h"
#import "idfunctions.h"

@class Storage;
@class BlockWorld;
extern	Storage	*sectors;
extern	BlockWorld	*blockworld_i;
extern	BOOL	fillerror;

@interface BlockWorld : NSObject

- (void)displayBlockMap;
- (void)createBlockMap;
- (void)drawBlockLine: (int) linenum;
- (void)floodFillSector: (NSPoint)pt;
- (BOOL)connectSectors;

@end
