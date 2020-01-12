// REDOOMED changes (c) 2019 Josh Freeman, distributed under GNU AGPL (v3 or later approved vers.)

#ifdef REDOOMED
#   import <Cocoa/Cocoa.h>
#else // Original
#   import <appkit/appkit.h>
#endif

typedef struct
{
	int	xoff,yoff;
	texpatch_t *p;
} delta_t;

@interface TextureView:View
{
	id	deltaTable;
}


@end
