#import "Storage.h"

#import <AppKit/AppKit.h>

typedef struct
{
	NSString *orgname, *newname;
} type_t;

//
//	Methods to be implemented by the delegate
//
@protocol Remapper
- (NSString *) getOriginalName;
- (NSString *) getNewName;
- (int)doRemap: (NSString *) oldname to: (NSString *) newname;
- (void)finishUp;
@end


@interface Remapper:NSObject <NSApplicationDelegate, NSBrowserDelegate, NSWindowDelegate>
{
	IBOutlet NSTextField	*original_i;
	IBOutlet NSTextField	*new_i;
	IBOutlet NSWindow		*remapPanel_i;
	IBOutlet NSTextField	*remapString_i;
	IBOutlet NSTextField	*status_i;
	IBOutlet NSBrowser		*browser_i;
	IBOutlet id		matrix_i;
	
	CompatibleStorage *storage_i;
	IBOutlet id<Remapper> delegate_i;
	NSString *frameName;
}

//	EXTERNAL USE
- (void)setFrameName:(NSString *)fname
  setPanelTitle:(NSString *)ptitle
  setBrowserTitle:(NSString *)btitle
  setRemapString:(NSString *)rstring
  setDelegate:(id<Remapper>)delegate;

//extern - (int)doRemap:(char *)oldname to:(char *)newname;

- (void)showPanel;
  
- (void)addToList: (NSString *) orgname to: (NSString *) newname;

//	INTERNAL USE
- (IBAction)remapGetButtons:sender;
- (IBAction)doRemappingOneMap:sender;
- (IBAction)doRemappingAllMaps:sender;
- (IBAction)addToList:sender;
- (IBAction)deleteFromList:sender;
- (IBAction)clearList:sender;

@end

