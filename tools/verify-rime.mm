// Standalone harness: deploy rime-data with the downloaded librime and
// simulate typing, to verify the vendored data set end to end.
// Build: clang++ -std=c++14 tools/verify-rime.mm -o /tmp/verify-rime \
//   -Ilibrime/dist/include -Llibrime/dist/lib -lrime.1 \
//   -F/System/Library/Frameworks -framework Foundation -rpath $(pwd)/librime/dist/lib
#import <Foundation/Foundation.h>
#import <rime_api.h>

static void type(RimeApi *api, RimeSessionId session, const char *keys) {
    for (const char *p = keys; *p; ++p) {
        int keysym = (unsigned char)*p;
        if (keysym >= 'a' && keysym <= 'z') {
            keysym = 0x61 + (keysym - 'a');
        }
        Bool handled = api->process_key(session, keysym, 0);
        printf("  key '%c' handled=%d\n", *p, handled);
        RimeCommit commit = {0};
        commit.data_size = sizeof(RimeCommit) - sizeof(commit.data_size);
        if (api->get_commit(session, &commit)) {
            printf("  COMMIT: %s\n", commit.text);
            api->free_commit(&commit);
        }
    }
    RimeContext ctx = {0};
    ctx.data_size = sizeof(RimeContext) - sizeof(ctx.data_size);
    if (api->get_context(session, &ctx)) {
        printf("  preedit: %s | candidates on page: %d | highlight: %d\n",
               ctx.composition.preedit ? ctx.composition.preedit : "(none)",
               ctx.menu.num_candidates, ctx.menu.highlighted_candidate_index);
        for (int i = 0; i < ctx.menu.num_candidates && i < 9; ++i) {
            printf("    %d. %s %s\n", i + 1, ctx.menu.candidates[i].text,
                   ctx.menu.candidates[i].comment ? ctx.menu.candidates[i].comment : "");
        }
        api->free_context(&ctx);
    }
}

int main(int argc, char **argv) {
    @autoreleasepool {
        NSString *shared = [NSString stringWithFormat:@"%s/rime-data", argv[1]];
        NSString *user = @"/tmp/hallelujah-rime-verify";
        [[NSFileManager defaultManager] removeItemAtPath:user error:nil];
        [[NSFileManager defaultManager] createDirectoryAtPath:user withIntermediateDirectories:YES attributes:nil error:nil];

        RimeApi *api = rime_get_api();
        RimeTraits traits = {0};
        traits.data_size = sizeof(RimeTraits) - sizeof(traits.data_size);
        traits.shared_data_dir = shared.UTF8String;
        traits.user_data_dir = user.UTF8String;
        traits.log_dir = "/tmp/hallelujah-rime-verify-log";
        traits.app_name = "im.hallelujah.verify";
        api->setup(&traits);
        api->initialize(&traits);
        printf("start_maintenance -> %d\n", api->start_maintenance(True));
        api->join_maintenance_thread();

        RimeSessionId session = api->create_session();
        printf("session %llu\n", (unsigned long long)session);
        RimeStatus status = {0};
        status.data_size = sizeof(RimeStatus) - sizeof(status.data_size);
        api->get_status(session, &status);
        printf("schema: %s simplified: %d\n", status.schema_id, status.is_simplified);
        api->free_status(&status);

        printf("== type nihao + space\n");
        type(api, session, "nihao ");
        printf("== type ni + escape\n");
        type(api, session, "nih");
        api->process_key(session, 0xff1b, 0); // Escape
        printf("== punctuation\n");
        type(api, session, ",. ");

        api->destroy_session(session);
        api->cleanup_all_sessions();
        api->finalize();
    }
    return 0;
}
