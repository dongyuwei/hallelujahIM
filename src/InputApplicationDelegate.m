#import "InputApplicationDelegate.h"


@implementation InputApplicationDelegate

-(NSMenu*)menu
{
	return _menu;
}


-(void)awakeFromNib
{
	NSMenuItem*		preferences = [_menu itemWithTag:1];
	
	if ( preferences ) {
		[preferences setAction:@selector(showPreferences:)];
	}
	
}

@end
