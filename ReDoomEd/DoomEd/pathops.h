// REDOOMED changes (c) 2019 Josh Freeman, distributed under GNU AGPL (v3 or later approved vers.)

#ifdef REDOOMED
#   import <Cocoa/Cocoa.h>
#else // Original
#   import <appkit/appkit.h>
#endif

void		StartPath (int path);
void		AddLine (int path, float x1, float y1, float x2, float y2);
void		FinishPath (int path);
BOOL	LineInRect (NXPoint *p1, NXPoint *p2, NXRect *r);
