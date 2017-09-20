#import "InputApplicationDelegate.h"


@implementation InputApplicationDelegate

-(NSMenu*)menu
{
	return _menu;
}


-(void)awakeFromNib
{
	NSMenuItem*		preferenceMenu = [_menu itemWithTag:1];
	
	if ( preferenceMenu ) {
		[preferenceMenu setAction:@selector(showPreferences:)];
	}
}

@end
