#import "RimeEngine.h"

#import <rime_api.h>

@implementation RimeCandidateItem
@end

@implementation RimeEngine {
    RimeApi *_api;
    BOOL _started;
}

// Counts UTF-16 units in the first `byteLength` bytes of a UTF-8 string.
static NSInteger utf16LengthOfBytes(const char *utf8, NSInteger byteLength) {
    if (!utf8 || byteLength <= 0) {
        return 0;
    }
    NSString *prefix = [[NSString alloc] initWithBytes:utf8 length:byteLength encoding:NSUTF8StringEncoding];
    return prefix ? prefix.length : 0;
}

+ (instancetype)sharedEngine {
    static RimeEngine *engine;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        engine = [[RimeEngine alloc] init];
    });
    return engine;
}

- (void)startWithSharedDataDir:(NSString *)sharedDataDir userDataDir:(NSString *)userDataDir {
    if (_started) {
        return;
    }
    _api = rime_get_api();

    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:userDataDir]) {
        [fileManager createDirectoryAtPath:userDataDir withIntermediateDirectories:YES attributes:nil error:nil];
    }
    NSString *logDir = [NSTemporaryDirectory() stringByAppendingPathComponent:@"hallelujah.rime.log"];
    if (![fileManager fileExistsAtPath:logDir]) {
        [fileManager createDirectoryAtPath:logDir withIntermediateDirectories:YES attributes:nil error:nil];
    }

    RIME_STRUCT(RimeTraits, traits);
    traits.shared_data_dir = sharedDataDir.UTF8String;
    traits.user_data_dir = userDataDir.UTF8String;
    traits.log_dir = logDir.UTF8String;
    traits.app_name = "im.hallelujah.rime";
    traits.min_log_level = 2; // ERROR, keep the IME quiet

    _api->setup(&traits);
    _api->initialize(&traits);

    // First launch (or updated data): deployment compiles the schemas into
    // user_data_dir; run it synchronously so sessions start on valid data.
    if (_api->start_maintenance(False)) {
        _api->join_maintenance_thread();
    }
    _started = YES;
}

- (void)shutdown {
    if (!_started) {
        return;
    }
    _api->cleanup_all_sessions();
    _api->finalize();
    _started = NO;
}

- (RimeSessionId)createSession {
    return _started ? _api->create_session() : 0;
}

- (void)destroySession:(RimeSessionId)session {
    if (session) {
        _api->destroy_session(session);
    }
}

- (BOOL)sessionAlive:(RimeSessionId)session {
    return session && _api->find_session(session);
}

- (BOOL)processKey:(RimeSessionId)session keycode:(int)keycode mask:(int)mask {
    return _api->process_key(session, keycode, mask);
}

- (NSString *)commitText:(RimeSessionId)session {
    RIME_STRUCT(RimeCommit, commit);
    if (!_api->get_commit(session, &commit)) {
        return @"";
    }
    NSString *text = commit.text ? [NSString stringWithUTF8String:commit.text] : @"";
    _api->free_commit(&commit);
    return text;
}

- (NSString *)rawInput:(RimeSessionId)session {
    const char *input = _api->get_input(session);
    return input ? [NSString stringWithUTF8String:input] : @"";
}

- (NSString *)preedit:(RimeSessionId)session
             selStart:(NSInteger *)selStart
            selLength:(NSInteger *)selLength
             caretPos:(NSInteger *)caretPos {
    if (selStart) {
        *selStart = 0;
    }
    if (selLength) {
        *selLength = 0;
    }
    if (caretPos) {
        *caretPos = 0;
    }

    RIME_STRUCT(RimeContext, context);
    if (!_api->get_context(session, &context)) {
        return @"";
    }

    NSString *preedit = @"";
    if (context.composition.preedit) {
        preedit = [NSString stringWithUTF8String:context.composition.preedit];
        if (selStart) {
            *selStart = utf16LengthOfBytes(context.composition.preedit, context.composition.sel_start);
        }
        if (selLength) {
            *selLength = utf16LengthOfBytes(context.composition.preedit, context.composition.sel_end) - (selStart ? *selStart : 0);
        }
        if (caretPos) {
            *caretPos = utf16LengthOfBytes(context.composition.preedit, context.composition.cursor_pos);
        }
    }
    _api->free_context(&context);
    return preedit;
}

- (NSArray<RimeCandidateItem *> *)candidates:(RimeSessionId)session {
    RIME_STRUCT(RimeContext, context);
    if (!_api->get_context(session, &context)) {
        return @[];
    }
    NSMutableArray<RimeCandidateItem *> *candidates = [NSMutableArray array];
    for (int i = 0; i < context.menu.num_candidates; ++i) {
        RimeCandidateItem *candidate = [[RimeCandidateItem alloc] init];
        if (context.menu.candidates[i].text) {
            candidate.text = [NSString stringWithUTF8String:context.menu.candidates[i].text];
        }
        if (context.menu.candidates[i].comment) {
            candidate.comment = [NSString stringWithUTF8String:context.menu.candidates[i].comment];
        }
        [candidates addObject:candidate];
    }
    _api->free_context(&context);
    return candidates;
}

- (NSInteger)highlightedIndex:(RimeSessionId)session {
    RIME_STRUCT(RimeContext, context);
    if (!_api->get_context(session, &context)) {
        return -1;
    }
    NSInteger highlighted = context.menu.highlighted_candidate_index;
    _api->free_context(&context);
    return highlighted;
}

- (BOOL)selectCandidateOnCurrentPage:(RimeSessionId)session index:(NSInteger)index {
    return _api->select_candidate_on_current_page(session, index);
}

- (BOOL)changePage:(RimeSessionId)session backward:(BOOL)backward {
    return _api->change_page(session, backward ? True : False);
}

- (void)clearComposition:(RimeSessionId)session {
    _api->clear_composition(session);
}

@end
