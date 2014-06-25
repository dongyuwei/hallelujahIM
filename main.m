#import <Cocoa/Cocoa.h>
#import <InputMethodKit/InputMethodKit.h>
#import "NDTrie.h"

const NSString* kConnectionName = @"Hallelujah_1_Connection";

IMKServer*      server;
IMKCandidates*  sharedCandidates;
NDMutableTrie*  trie;
NSDictionary* wordsWithFrequency;

NDMutableTrie* buildTrieFromFile(){
    NSString* path = [[NSBundle mainBundle] pathForResource:@"google_227800_words"
                                                     ofType:@"json"];
    
    NSInputStream *inputStream = [[NSInputStream alloc] initWithFileAtPath: path];
    [inputStream  open];
    wordsWithFrequency  = [NSJSONSerialization JSONObjectWithStream:inputStream
                                                                 options:nil
                                                                   error:nil];
    [inputStream close];
    
    return [NDMutableTrie trieWithArray: [wordsWithFrequency allKeys]];
}

int main(int argc, char *argv[])
{
    NSString*       identifier;
    
    identifier = [[NSBundle mainBundle] bundleIdentifier];
    server = [[IMKServer alloc] initWithName:(NSString*)kConnectionName
                            bundleIdentifier:[[NSBundle mainBundle] bundleIdentifier]];
    
    sharedCandidates = [[IMKCandidates alloc] initWithServer:server
                                                   panelType:kIMKSingleColumnScrollingCandidatePanel];
    if (!sharedCandidates){
        NSLog(@"Fatal error: Cannot initialize shared candidate panel with connection %@.", kConnectionName);
        return -1;
    }
    
    trie =  buildTrieFromFile();
    
    [[NSBundle mainBundle] loadNibNamed:@"MainMenu"
                                  owner:[NSApplication sharedApplication]
                        topLevelObjects:nil];
	
	
	[[NSApplication sharedApplication] run];
	
    return 0;
}
