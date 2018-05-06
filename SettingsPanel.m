
#import "SettingsPanel.h"
#import "PreferencePanel.h"

SettingsPanel *settingspanel_i;

@implementation SettingsPanel

- init
{
	settingspanel_i = self;
	segmenttype = ONESIDED_C;
	return self;
}


- (IBAction)menuTarget:sender
{
}

- (int) segmentType
{
	return segmenttype;
}

@end
