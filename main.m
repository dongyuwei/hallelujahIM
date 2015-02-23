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
    
    trie =  buildTrieFromFile();
    
    
    LevelDBOptions options = [LevelDB makeOptions];
    options.createIfMissing = true;
    options.compression     = false;
    LevelDB *ldb = [[LevelDB alloc] init];
    ldb = [ldb initWithPath:@"/Users/ywdong/code/input-method/hallelujahIM/translation.ldb" name:@"translation.ldb" andOptions: options];
    
    
//    NSString* path = [[NSBundle mainBundle] pathForResource:@"all_translation" ofType:@"json"];
//    
//    NSInputStream *inputStream = [[NSInputStream alloc] initWithFileAtPath: path];
//    [inputStream  open];
//    NSDictionary* dict = [NSJSONSerialization JSONObjectWithStream:inputStream
//                                                           options:nil
//                                                             error:nil];
//    
//    [inputStream close];
//    
//    for(id key in dict){
//        NSLog(@"key=%@ value=%@", key, [dict objectForKey:key]);
//        ldb[key] = [dict objectForKey:key];
//    }
    
    NSLog(@"String Value: %@", ldb[@"name"]);
    
    [[NSBundle mainBundle] loadNibNamed:@"MainMenu"
                                  owner:[NSApplication sharedApplication]
                        topLevelObjects:nil];
	
	
	[[NSApplication sharedApplication] run];
	
    return 0;
}
