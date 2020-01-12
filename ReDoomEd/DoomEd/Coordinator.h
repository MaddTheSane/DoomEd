// REDOOMED changes (c) 2019 Josh Freeman, distributed under GNU AGPL (v3 or later approved vers.)

#ifdef REDOOMED
#   import <Cocoa/Cocoa.h>
#else // Original
#   import <appkit/appkit.h>
#endif

extern	id	coordinator_i;

extern	BOOL	debugflag;

#ifdef REDOOMED
#   define	TOOLNAME	@"ToolPanel"
#else // Original
#   define	TOOLNAME	"ToolPanel"
#endif

@interface Coordinator:Object
{
	id	toolPanel_i;
	id	infoPanel_i;
	id	startupSound_i;

#ifdef REDOOMED
	IBOutlet NSMenu *_mainMenu_OSX;
#endif
}

- toggleDebug: sender;
- redraw: sender;
@end
