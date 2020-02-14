// doombsp.h

#import <AppKit/AppKit.h>
#import <math.h>
#import "cmdlib.h"
#import "idfunctions.h"

#define	SHORT(x)	CFSwapInt16LittleToHost((short)x)
#define	LONG(x)		CFSwapInt32LittleToHost(x)

#define PI	3.141592657

/*
===============================================================================

							map file types

===============================================================================
*/

typedef struct
{
	int			floorheight, ceilingheight;
	char 		floorflat[9], ceilingflat[9];
	int			lightlevel;
	int			special, tag;	
} sectordef_t;

typedef struct
{
	int			firstrow;	
	int			firstcollumn;
	char		toptexture[9];
	char		bottomtexture[9];
	char		midtexture[9];
	sectordef_t	sectordef;			// on the viewer's side
	int			sector;				// only used when saving doom map
} worldside_t;

typedef struct
{
	NXPoint		p1, p2;
	int			special, tag;
	int			flags;	
	worldside_t	side[2];
} worldline_t;

#define	ML_BLOCKMOVE	1
#define	ML_TWOSIDED		4	// backside will not be present at all if not two sided

typedef struct
{
	NXPoint		origin;
	int			angle;
	int			type;
	int			options;
	int			area;
} worldthing_t;


/*
===============================================================================

								doomload

===============================================================================
*/

extern Storage *linestore_i;
extern Storage *thingstore_i;

void LoadDoomMap (char *mapname);

extern int DoomPrintMain (int argc, char **argv);
