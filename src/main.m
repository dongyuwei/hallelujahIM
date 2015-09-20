#import <Cocoa/Cocoa.h>
#import <InputMethodKit/InputMethodKit.h>
#import "PJTernarySearchTree.h"
@import SSKeychain;

const NSString*         kConnectionName = @"Hallelujah_1_Connection";
IMKServer*              server;
IMKCandidates*          sharedCandidates;
IMKCandidates*          subCandidates;
PJTernarySearchTree*    trie;
NSString*               dictName = @"google_227800_words";
NSMutableDictionary*    wordsWithFrequency;
BOOL                    defaultEnglishMode;
NSDictionary*           translationes;

PJTernarySearchTree* buildTrieFromFile(){
    NSString* path = [[NSBundle mainBundle] pathForResource:dictName ofType:@"json"];
    
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

int main(int argc, char *argv[])
{
    NSError *error = nil;
    NSString* token = [SSKeychain passwordForService:@"Internet password" account:@"Instagram" error:&error];
    if ([error code] == errSecItemNotFound) {
        NSLog(@"Password not found");
        [SSKeychain setPassword: @"test" forService:@"Internet password" account:@"Instagram"];
        NSLog(@"Data saved to keychain");
    } else if (error != nil) {
        NSLog(@"Some other error occurred: %@", [error localizedDescription]);
    }
    NSLog(@"token: %@", token);

    
    
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
    
    
	[[NSApplication sharedApplication] run];
    
    
    return 0;
}
