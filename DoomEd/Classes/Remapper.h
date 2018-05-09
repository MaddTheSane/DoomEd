#import "Storage.h"

#import <AppKit/AppKit.h>

@interface RemapperObject: NSObject
{
	NSString *orgname, *newname;
}
@property (copy) NSString *originalName;
@property (copy) NSString *changeToName;
@end

/// Methods to be implemented by the delegate
@protocol RemapperDelegate <NSObject>
- (NSString *) getOriginalName;
- (NSString *) getNewName;
- (NSInteger)doRemap: (NSString *) oldname to: (NSString *) newname;
- (void)finishUp;
@end


@interface Remapper:NSObject <NSBrowserDelegate, NSWindowDelegate>
{
	IBOutlet NSTextField	*original_i;
	IBOutlet NSTextField	*new_i;
	IBOutlet NSWindow		*remapPanel_i;
	IBOutlet NSTextField	*remapString_i;
	IBOutlet NSTextField	*status_i;
	IBOutlet NSBrowser		*browser_i;
	IBOutlet NSMatrix		*matrix_i;
	
	NSMutableArray<RemapperObject*> *storage_i;
	IBOutlet id<RemapperDelegate> delegate_i;
	NSString *frameName;
}

//	EXTERNAL USE
- (void)setFrameName:(NSString *)fname
  setPanelTitle:(NSString *)ptitle
  setBrowserTitle:(NSString *)btitle
  setRemapString:(NSString *)rstring
  setDelegate:(id<RemapperDelegate>)delegate;
@property (assign) IBOutlet id<RemapperDelegate> delegate;

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

