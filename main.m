#import <Cocoa/Cocoa.h>
#import <InputMethodKit/InputMethodKit.h>
#import "NDTrie.h"
#import <LevelDB.h>

const NSString*         kConnectionName = @"Hallelujah_1_Connection";
IMKServer*              server;
IMKCandidates*          sharedCandidates;
IMKCandidates*          subCandidates;
NDMutableTrie*          trie;
NSString*               dictName = @"google_227800_words";
NSMutableDictionary*    wordsWithFrequency;
BOOL                    defaultEnglishMode;
NSDictionary*           translationes;

NDMutableTrie* buildTrieFromFile(){
    NSString* path = [[NSBundle mainBundle] pathForResource:dictName ofType:@"json"];
    
    NSInputStream *inputStream = [[NSInputStream alloc] initWithFileAtPath: path];
    [inputStream  open];
    NSDictionary* dict = [NSJSONSerialization JSONObjectWithStream:inputStream
                                                                 options:nil
                                                                   error:nil];
    
    wordsWithFrequency = [dict mutableCopy];
    [inputStream close];
    
    return [NDMutableTrie trieWithArray: [wordsWithFrequency allKeys]];
}

NSDictionary* getTranslationes(){
    NSString* path = [[NSBundle mainBundle] pathForResource:@"transformed_translation" ofType:@"json"];
    
    NSInputStream *inputStream = [[NSInputStream alloc] initWithFileAtPath: path];
    [inputStream  open];
    NSDictionary* translationes = [NSJSONSerialization JSONObjectWithStream:inputStream
                                                                    options:nil
                                                                      error:nil];
    
    [inputStream close];
    
    NSLog(@"value=%@",[translationes objectForKey: @"good"]);
    
    return translationes;
}

int main(int argc, char *argv[])
{
    NSString*       identifier;
    
    identifier = [[NSBundle mainBundle] bundleIdentifier];
    server = [[IMKServer alloc] initWithName:(NSString*)kConnectionName
                            bundleIdentifier:[[NSBundle mainBundle] bundleIdentifier]];
    
    sharedCandidates = [[IMKCandidates alloc] initWithServer:server panelType:kIMKSingleColumnScrollingCandidatePanel];
    subCandidates    = [[IMKCandidates alloc] initWithServer:nil    panelType:kIMKSingleColumnScrollingCandidatePanel];
    
    if (!sharedCandidates){
        NSLog(@"Fatal error: Cannot initialize shared candidate panel with connection %@.", kConnectionName);
        return -1;
    }
    
    trie = buildTrieFromFile();
    translationes = getTranslationes();
    
    [[NSBundle mainBundle] loadNibNamed:@"MainMenu"
                                  owner:[NSApplication sharedApplication]
                        topLevelObjects:nil];
	
//    NSRect frame = NSMakeRect(0, 0, 300, 300);
//    NSWindow* window  = [[NSWindow alloc] initWithContentRect:frame
//                                                     styleMask:NSClosableWindowMask
//                                                       backing:NSBackingStoreRetained
//                                                         defer:NO] ;
//    
//    NSView *view = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 300, 300)];
//    [view setWantsLayer:YES];
//    view.layer.backgroundColor = [[NSColor yellowColor] CGColor];
//    
//    [window setContentView:view];
//    
//    [window makeKeyAndOrderFront:nil];
//    [window setLevel:NSStatusWindowLevel];
//	
//    NSAttributedString* word = [[NSAttributedString alloc] initWithString:@"test"];
//    [view showDefinitionForAttributedString:word atPoint:NSMakePoint(150,150)];
    
    
	[[NSApplication sharedApplication] run];
    
    
    return 0;
}
