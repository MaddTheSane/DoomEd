
#import <AppKit/AppKit.h>

@interface SettingsPanel:NSObject
{
	int	segmenttype;
}

- (IBAction)menuTarget:sender;
@property (readonly) int segmentType;

@end

extern SettingsPanel *settingspanel_i;

