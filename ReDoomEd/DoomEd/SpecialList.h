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

//
//	Methods to be implemented by the delegate
//
@protocol SpecialList <NSObject>
- specialChosen:(int)value;
@end

@interface SpecialList:NSObject
{
	IBOutlet id	specialDesc_i;
	IBOutlet id	specialBrowser_i;
	IBOutlet id	specialValue_i;
	IBOutlet id	specialPanel_i;
	Storage	*specialList_i;
	
	__unsafe_unretained id<SpecialList>	delegate;
	char		title[32];
	char		frameString[32];
}

@property (readonly, retain) Storage *specialList;
- scrollToItem:(int)i;
- setSpecialTitle:(char *)string;
- setFrameName:(char *)string;
- saveFrame;

#ifdef REDOOMED
// Declare setDelegate: publicly
@property (assign) id<SpecialList> delegate;
#endif

- displayPanel;
- (IBAction)addSpecial:sender;
- (IBAction)suggestValue:sender;
- (IBAction)chooseSpecial:sender;
- updateSpecialsDSP:(FILE *)stream;
- (NSInteger)findSpecial:(int)value;
- validateSpecialString:sender;
- setSpecial:(int)which;
- fillSpecialData:(speciallist_t *)special;

- (void)empty;
@end
