// REDOOMED changes (c) 2019 Josh Freeman, distributed under GNU AGPL (v3 or later approved vers.)

#ifdef REDOOMED
#   import <Cocoa/Cocoa.h>
#else // Original
#   import <appkit/appkit.h>
#endif

@interface FindLine:Object
{
	id	window_i;
	id	status_i;
	id	numfield_i;
	id	delSound;
	id	fromBSP_i;
}

#define MARGIN		64			// margin from window edge

#ifdef REDOOMED
#   define	PREFNAME	@"FindLinePanel"
#else // Original
#   define	PREFNAME	"FindLinePanel"
#endif

- (int)getRealLineNum:(int)num;
- findLine:sender;
- deleteLine:sender;
- menuTarget:sender;
- (void)rectFromPoints:(NXRect *)r p1:(NXPoint)p1 p2:(NXPoint)p2;

@end
