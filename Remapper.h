#import "Storage.h"

#import <appkit/appkit.h>

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
- finishUp;
@end


@interface Remapper:NSObject <NSApplicationDelegate>
{
	IBOutlet id		original_i;
	IBOutlet id		new_i;
	IBOutlet id		remapPanel_i;
	IBOutlet id		remapString_i;
	IBOutlet id		status_i;
	IBOutlet id		browser_i;
	IBOutlet id		matrix_i;
	
	CompatibleStorage *storage_i;
	IBOutlet id		delegate_i;
	NSString *frameName;
}

//	EXTERNAL USE
- (void)setFrameName:(NSString *)fname
  setPanelTitle:(NSString *)ptitle
  setBrowserTitle:(NSString *)btitle
  setRemapString:(NSString *)rstring
  setDelegate:(id)delegate;

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
