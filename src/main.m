#import <Cocoa/Cocoa.h>
#import <InputMethodKit/InputMethodKit.h>
#import "PJTernarySearchTree.h"

const NSString*         kConnectionName = @"Hallelujah_1_Connection";
IMKServer*              server;
IMKCandidates*          sharedCandidates;
PJTernarySearchTree*    trie;
NSMutableDictionary*    wordsWithFrequency;
BOOL                    defaultEnglishMode;
NSDictionary*           translationes;
NSDictionary*           substitutions;

PJTernarySearchTree* buildTrieFromFile(){
    NSString* path = [[NSBundle mainBundle] pathForResource:@"google_227800_words" ofType:@"json"];
    
    NSInputStream *inputStream = [[NSInputStream alloc] initWithFileAtPath: path];
    [inputStream  open];
    NSDictionary* dict = [NSJSONSerialization JSONObjectWithStream:inputStream
                                                                 options:nil
                                                                   error:nil];
    
    wordsWithFrequency = [dict mutableCopy];
    [inputStream close];
    
    PJTernarySearchTree * tree = [[PJTernarySearchTree alloc] init];
    
    NSArray * allWords = [wordsWithFrequency allKeys];
    for(NSString* word in allWords){
        [tree insertString: word];
    }
    
    return tree;
}

NSDictionary* getTranslationes(){
    NSString* path = [[NSBundle mainBundle] pathForResource:@"transformed_translation" ofType:@"json"];
    
    NSInputStream *inputStream = [[NSInputStream alloc] initWithFileAtPath: path];
    [inputStream  open];
    NSDictionary* translationes = [NSJSONSerialization JSONObjectWithStream:inputStream
                                                                    options:nil
                                                                      error:nil];
    
    [inputStream close];
    
    return translationes;
}

NSDictionary* getUserDefinedSubstitutions(){
    NSString* path =[NSString stringWithFormat:@"%@%@", NSHomeDirectory(), @"/.you_expand_me.json"];
    
    NSInputStream *inputStream = [[NSInputStream alloc] initWithFileAtPath: path];
    [inputStream  open];
    NSDictionary* substitutions = [NSJSONSerialization JSONObjectWithStream:inputStream
                                                                    options:nil
                                                                      error:nil];
    
    [inputStream close];
    return substitutions;
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
    
    trie = buildTrieFromFile();
    translationes = getTranslationes();
    substitutions = getUserDefinedSubstitutions();
    
    [[NSBundle mainBundle] loadNibNamed:@"MainMenu"
                                  owner:[NSApplication sharedApplication]
                        topLevelObjects:nil];
    
	[[NSApplication sharedApplication] run];
    
    return 0;
}
