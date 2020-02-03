#import "EditWorld.h"
#import "idfunctions.h"

@class Storage;
@class BlockWorld;
extern	Storage	*sectors;
extern	BlockWorld	*blockworld_i;
extern	BOOL	fillerror;

@interface BlockWorld : NSObject

- displayBlockMap;
- createBlockMap;
- drawBlockLine: (int) linenum;
- floodFillSector: (NXPoint *)pt;
- (BOOL)connectSectors;

@end
