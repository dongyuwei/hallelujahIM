#import <Cocoa/Cocoa.h>
#import <InputMethodKit/InputMethodKit.h>
#import "marisa.h"

const NSString*         kConnectionName = @"Hallelujah_1_Connection";
IMKServer*              server;
IMKCandidates*          sharedCandidates;
marisa::Trie            trie;
BOOL                    defaultEnglishMode;
NSDictionary*           wordsWithFrequencyAndTranslation;
NSDictionary*           substitutions;


NSDictionary* getWordsWithFrequencyAndTranslation(){
    NSString* path = [[NSBundle mainBundle] pathForResource:@"words_with_frequency_and_translation" ofType:@"json"];
    
    NSInputStream *inputStream = [[NSInputStream alloc] initWithFileAtPath: path];
    [inputStream  open];
    NSDictionary* words = [NSJSONSerialization JSONObjectWithStream:inputStream
                                                                    options:nil
                                                                      error:nil];
    
    [inputStream close];
    
    return words;
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
    
    NSString* path = [[NSBundle mainBundle] pathForResource:@"google_227800_words" ofType:@"bin"];
    const char *path2 = [path cStringUsingEncoding:[NSString defaultCStringEncoding]];
    trie.load(path2);
    
    wordsWithFrequencyAndTranslation = getWordsWithFrequencyAndTranslation();
    substitutions = getUserDefinedSubstitutions();
    
    [[NSBundle mainBundle] loadNibNamed:@"MainMenu"
                                  owner:[NSApplication sharedApplication]
                        topLevelObjects:nil];
    
	[[NSApplication sharedApplication] run];
    
    return 0;
}
