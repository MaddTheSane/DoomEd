
#import "SettingsPanel.h"
#import "PreferencePanel.h"

SettingsPanel *settingspanel_i;

@implementation SettingsPanel

- init
{
	if (self = [super init]) {
	settingspanel_i = self;
	segmenttype = ONESIDED_C;
	}
	
	return self;
}


- (IBAction)menuTarget:sender
{
}

@synthesize segmentType=segmenttype;

@end
