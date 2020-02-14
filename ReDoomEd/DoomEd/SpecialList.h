// REDOOMED changes (c) 2019 Josh Freeman, distributed under GNU AGPL (v3 or later approved vers.)

#ifdef REDOOMED
#   import <Cocoa/Cocoa.h>
#else // Original
#   import <appkit/appkit.h>
#endif

typedef struct
{
	int		value;
	char		desc[32];
} speciallist_t;

@class Storage;
@class SpecialListWindow;

//
//	Methods to be implemented by the delegate
//
@protocol SpecialList <NSObject>
- (void)specialChosen:(int)value;
@end

@interface SpecialList:NSObject
{
	IBOutlet NSTextField	*specialDesc_i;
	IBOutlet NSBrowser		*specialBrowser_i;
	IBOutlet NSTextField	*specialValue_i;
	IBOutlet SpecialListWindow	*specialPanel_i;
	Storage	*specialList_i;
	
	__unsafe_unretained id<SpecialList>	delegate;
	char		title[32];
	NSString	*frameString;
}

@property (readonly, retain) Storage *specialList;
- (void)scrollToItem:(int)i;
- (void)setSpecialTitle:(char *)string;
@property (copy) NSString *frameName;
- (void)saveFrame;

#ifdef REDOOMED
// Declare setDelegate: publicly
@property (assign) id<SpecialList> delegate;
#endif

- (void)displayPanel;
- (IBAction)addSpecial:sender;
- (IBAction)suggestValue:sender;
- (IBAction)chooseSpecial:sender;
- (void)updateSpecialsDSP:(FILE *)stream;
- (NSInteger)findSpecial:(int)value;
- (IBAction)validateSpecialString:sender;
- (void)setSpecial:(int)which;
- (void)fillSpecialData:(speciallist_t *)special;

- (void)empty;
@end
