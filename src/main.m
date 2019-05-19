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
    NSDate *start = [NSDate date];
    NSString* path = [[NSBundle mainBundle] pathForResource:@"google_227800_words" ofType:@"json"];
    
    NSInputStream *inputStream = [[NSInputStream alloc] initWithFileAtPath: path];
    [inputStream  open];
    NSDictionary* dict = [NSJSONSerialization JSONObjectWithStream:inputStream
                                                                 options:nil
                                                                   error:nil];
    
    wordsWithFrequency = [dict mutableCopy];
    [inputStream close];
    NSTimeInterval timeInterval = [start timeIntervalSinceNow];
    NSLog(@"read json:%f", timeInterval);// 0.103535s not so bad
    NSDate *start2 = [NSDate date];
    
    PJTernarySearchTree * tree = [[PJTernarySearchTree alloc] init];
    
    NSArray * allWords = [wordsWithFrequency allKeys];
    for(NSString* word in allWords){
        [tree insertString: word];
    }
    NSTimeInterval timeInterval2 = [start2 timeIntervalSinceNow];
    NSLog(@"build trie:%f", timeInterval2);// 0.349201s slow
    
    NSDate *start3 = [NSDate date];
    NSString* savePath =[NSString stringWithFormat:@"%@%@", NSHomeDirectory(), @"/.hallelujah_data"];
    [tree saveTreeToFile: savePath];
    
    NSTimeInterval timeInterval3 = [start3 timeIntervalSinceNow];
    NSLog(@"save trie:%f", timeInterval3);// 3.877789s slow
    
    NSDate *start4 = [NSDate date];
    PJTernarySearchTree * tree2 = [PJTernarySearchTree treeWithFile: savePath];
    NSTimeInterval timeInterval4 = [start4 timeIntervalSinceNow];
    NSLog(@"rebuild trie:%f", timeInterval4);//1.912802 slow

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
    NSLog(@"substitutions:%@", substitutions);
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
