
#import "Storage.h"
#import <AppKit/AppKit.h>

typedef struct
{
	int		value;
	char		desc[32];
} speciallist_t;

@class SpecialListWindow;
@protocol SpecialListDelegate <NSObject>
- (void)specialChosen: (int)value;
@end

@interface SpecialList:NSObject <NSMatrixDelegate, NSBrowserDelegate>
{
	IBOutlet NSTextField	*specialDesc_i;
	IBOutlet NSBrowser		*specialBrowser_i;
	IBOutlet NSTextField	*specialValue_i;
	IBOutlet SpecialListWindow	*specialPanel_i;
	CompatibleStorage *specialList_i;

	id<SpecialListDelegate> delegate;
	char		title[32];
	char		frameString[32];
}
@property (assign) IBOutlet id<SpecialListDelegate> delegate;

- (CompatibleStorage *) getSpecialList;
- (void)scrollToItem:(int)i;
- (void)setSpecialTitle:(const char *)string;
- (void)setFrameName:(const char *)string;
- (void)saveFrame;
- (void)displayPanel;
- (IBAction)addSpecial:sender;
- (IBAction)suggestValue:sender;
- (IBAction)chooseSpecial:sender;
- (void)updateSpecialsDSP:(FILE *)stream;
- (int)findSpecial:(int)value;
- (IBAction)validateSpecialString:sender;
- (void)setSpecial:(int)which;
- (void)fillSpecialData:(speciallist_t *)special;
- (void)empty;

@end

