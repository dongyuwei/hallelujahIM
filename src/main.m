#import <Cocoa/Cocoa.h>
#import <InputMethodKit/InputMethodKit.h>
#import "FMDatabase.h"



const NSString*         kConnectionName = @"Hallelujah_1_Connection";
IMKServer*              server;
IMKCandidates*          sharedCandidates;
FMDatabase*             db;
BOOL                    defaultEnglishMode;

FMDatabase* shuangpinDB(){
    NSString* path = [[NSBundle mainBundle] pathForResource:@"shuangpin-sqlite" ofType:@"db"];
    FMDatabase *db = [FMDatabase databaseWithPath: path];
    [db open];
    
    return db;
}


int main(int argc, char *argv[])
{
    NSString*       identifier;
    
    identifier = [[NSBundle mainBundle] bundleIdentifier];
    server = [[IMKServer alloc] initWithName:(NSString*)kConnectionName
                            bundleIdentifier:[[NSBundle mainBundle] bundleIdentifier]];
    
    sharedCandidates = [[IMKCandidates alloc] initWithServer:server panelType:kIMKSingleColumnScrollingCandidatePanel];
    
    if (!sharedCandidates){
        NSLog(@"Fatal error: Cannot initialize shared candidate panel with connection %@.", kConnectionName);
        return -1;
    }
    
    db = shuangpinDB();

        
    [[NSBundle mainBundle] loadNibNamed:@"MainMenu"
                                  owner:[NSApplication sharedApplication]
                        topLevelObjects:nil];
    
	[[NSApplication sharedApplication] run];
    
    return 0;
}