
#import "Storage.h"
#import <appkit/appkit.h>

typedef struct
{
	int		value;
	char		desc[32];
} speciallist_t;

@protocol SpecialListDelegate <NSObject>
- (void)specialChosen: (int)value;
@end

@interface SpecialList:NSObject <NSMatrixDelegate>
{
	IBOutlet id	specialDesc_i;
	IBOutlet id	specialBrowser_i;
	IBOutlet id	specialValue_i;
	IBOutlet id	specialPanel_i;
	CompatibleStorage *specialList_i;

	id<SpecialListDelegate> delegate;
	char		title[32];
	char		frameString[32];
}
@property (assign) IBOutlet id<SpecialListDelegate> delegate;

- (CompatibleStorage *) getSpecialList;
- (void)scrollToItem:(int)i;
- (void)setSpecialTitle:(char *)string;
- (void)setFrameName:(char *)string;
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

