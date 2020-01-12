// REDOOMED changes (c) 2019 Josh Freeman, distributed under GNU AGPL (v3 or later approved vers.)

#import "SettingsPanel.h"
#import "PreferencePanel.h"

id	settingspanel_i;

@implementation SettingsPanel

- init
{
#ifdef REDOOMED
	self = [super init];

	if (!self)
		return nil;
#endif

	settingspanel_i = self;
	segmenttype = ONESIDED_C;
	return self;
}


- menuTarget:sender
{
    return self;
}

- (int) segmentType
{
	return segmenttype;
}

@end
