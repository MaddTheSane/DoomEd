// REDOOMED changes (c) 2019 Josh Freeman, distributed under GNU AGPL (v3 or later approved vers.)

#ifdef REDOOMED
#   import <Cocoa/Cocoa.h>
#else // Original
#   import <appkit/appkit.h>
#endif

@class Storage;

///
///	Methods to be implemented by the delegate
///
@protocol Remapper <NSObject>
- (NSString *)originalName;
- (NSString *)newName NS_RETURNS_NOT_RETAINED;
- (int)doRemapFromName:(NSString *)oldname toName:(NSString *)newname;
- (void)finishUp;

@optional
- (int)doRemap:(char *)oldname to:(char *)newname API_DEPRECATED_WITH_REPLACEMENT("-doRemapFromName:toName:", macos(10.0, 10.0));
@end


@interface Remapper:NSObject <NSBrowserDelegate>
{
	IBOutlet NSTextField *original_i;
	IBOutlet NSTextField *new_i;
	IBOutlet NSWindow *remapPanel_i;
	IBOutlet NSTextField *remapString_i;
	IBOutlet NSTextField *status_i;
	IBOutlet NSBrowser *browser_i;
	IBOutlet NSMatrix *matrix_i;
	
	__unsafe_unretained id<Remapper>		delegate_i;
	NSString *frameName;
}

//	EXTERNAL USE
- setFrameName:(char *)fname
  setPanelTitle:(char *)ptitle
  setBrowserTitle:(char *)btitle
  setRemapString:(char *)rstring
  setDelegate:(id<Remapper>)delegate API_DEPRECATED_WITH_REPLACEMENT("-setFrameName:panelTitle:browserTitle:remapString:delegate:", macos(10.0, 10.0));

- (void)setFrameName:(NSString *)fname
		  panelTitle:(NSString *)ptitle
		browserTitle:(NSString *)btitle
		 remapString:(NSString *)rstring
			delegate:(id<Remapper>)delegate;

//extern - (int)doRemap:(char *)oldname to:(char *)newname;

- (void)showPanel;
  
- (void)addToListFromName:(NSString *)orgname toName:(NSString *)newname;

//	INTERNAL USE
- (IBAction)remapGetButtons:sender;
- (IBAction)doRemappingOneMap:sender;
- (IBAction)doRemappingAllMaps:sender;
- (IBAction)addToList:sender;
- (IBAction)deleteFromList:sender;
- (IBAction)clearList:sender;

@end
