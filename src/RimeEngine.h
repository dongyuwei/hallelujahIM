#import <Foundation/Foundation.h>
#import <rime_api.h>

// Thin Objective-C wrapper around librime's C API, backing the pinyin mode.
// librime is initialized once per process; each IMKInputController owns a session.

@interface RimeCandidateItem : NSObject

@property(nonatomic, copy) NSString *text;
@property(nonatomic, copy) NSString *comment;

@end

@interface RimeEngine : NSObject

+ (instancetype)sharedEngine;

// Starts librime: shared_data_dir holds the bundled rime-data, user_data_dir
// receives the compiled artifacts on first run (deployment happens here).
- (void)startWithSharedDataDir:(NSString *)sharedDataDir userDataDir:(NSString *)userDataDir;

- (void)shutdown;

- (RimeSessionId)createSession;
- (void)destroySession:(RimeSessionId)session;
- (BOOL)sessionAlive:(RimeSessionId)session;

// Feeds one translated key event; returns YES when Rime consumed it.
- (BOOL)processKey:(RimeSessionId)session keycode:(int)keycode mask:(int)mask;

// Committed text pending delivery ("" when none).
- (NSString *)commitText:(RimeSessionId)session;

// The raw (unconverted) input, for committing on deactivation.
- (NSString *)rawInput:(RimeSessionId)session;

// Inline preedit: whole composition string, plus the converted range
// [selStart, selLength) in UTF-16 units and the caret position.
- (NSString *)preedit:(RimeSessionId)session selStart:(NSInteger *)selStart selLength:(NSInteger *)selLength caretPos:(NSInteger *)caretPos;

// Candidates on the current page.
- (NSArray<RimeCandidateItem *> *)candidates:(RimeSessionId)session;

// Page and highlight state; both -1 when there is no composition.
- (NSInteger)highlightedIndex:(RimeSessionId)session;
- (BOOL)selectCandidateOnCurrentPage:(RimeSessionId)session index:(NSInteger)index;
- (BOOL)changePage:(RimeSessionId)session backward:(BOOL)backward;

- (void)clearComposition:(RimeSessionId)session;

@end
