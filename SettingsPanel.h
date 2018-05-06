
#import <AppKit/AppKit.h>

@interface SettingsPanel:NSObject
{
	int	segmenttype;
}

- (IBAction)menuTarget:sender;
- (int) segmentType;

@end

extern SettingsPanel *settingspanel_i;

