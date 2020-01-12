// REDOOMED changes (c) 2019 Josh Freeman, distributed under GNU AGPL (v3 or later approved vers.)

#import "MapView.h"

@interface MapView (MapViewResp)

#ifdef REDOOMED
// Cocoa versions
- (void) mouseDown:(NSEvent *)thisEvent;
- (void) rightMouseDown:(NSEvent *)thisEvent;
#else // Original
- mouseDown:(NXEvent *)thisEvent;
- rightMouseDown:(NXEvent *)thisEvent;
#endif

@end
