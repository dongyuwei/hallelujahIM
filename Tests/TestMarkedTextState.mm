#import "MarkedTextState.h"
#import <XCTest/XCTest.h>

// The marked-text skip rules. Getting one of these wrong makes the input method
// either drop typed characters (skipping an update the client never saw) or
// hand every keystroke to the client twice, so they are pinned here - with no
// AppKit and no client, which is why the state lives in its own class.
@interface TestMarkedTextState : XCTestCase
@property(nonatomic, strong) MarkedTextState *state;
@property(nonatomic, strong) NSObject *client;
@end

@implementation TestMarkedTextState

- (void)setUp {
    self.state = [[MarkedTextState alloc] init];
    self.client = [[NSObject alloc] init];
}

- (void)testIdenticalUpdateIsSkipped {
    [self.state recordString:@"ni" selectionRange:NSMakeRange(2, 0) client:self.client];
    XCTAssertTrue([self.state isCurrentForString:@"ni" selectionRange:NSMakeRange(2, 0) client:self.client]);
}

- (void)testUnrecordedStateIsNeverCurrent {
    XCTAssertFalse([self.state isCurrentForString:@"ni" selectionRange:NSMakeRange(2, 0) client:self.client]);
}

- (void)testDifferentStringIsDelivered {
    [self.state recordString:@"ni" selectionRange:NSMakeRange(2, 0) client:self.client];
    XCTAssertFalse([self.state isCurrentForString:@"ha" selectionRange:NSMakeRange(2, 0) client:self.client]);
}

// The caret/converted range moves while the string stays the same, as Rime's
// converted segment grows while a composition is resolved.
- (void)testDifferentSelectionIsDelivered {
    [self.state recordString:@"ni" selectionRange:NSMakeRange(2, 0) client:self.client];
    XCTAssertFalse([self.state isCurrentForString:@"ni" selectionRange:NSMakeRange(1, 1) client:self.client]);
}

// A second client never saw what the first one was sent.
- (void)testDifferentClientIsDelivered {
    [self.state recordString:@"ni" selectionRange:NSMakeRange(2, 0) client:self.client];
    NSObject *otherClient = [[NSObject alloc] init];
    XCTAssertFalse([self.state isCurrentForString:@"ni" selectionRange:NSMakeRange(2, 0) client:otherClient]);
}

- (void)testNilClientIsNeverCurrent {
    [self.state recordString:@"ni" selectionRange:NSMakeRange(2, 0) client:self.client];
    XCTAssertFalse([self.state isCurrentForString:@"ni" selectionRange:NSMakeRange(2, 0) client:nil]);
}

// The regression that matters: after a commit the client's composition is gone,
// so a new composition that happens to repeat the same string must be sent.
- (void)testForgetForcesDeliveryOfTheSameString {
    [self.state recordString:@"ni" selectionRange:NSMakeRange(2, 0) client:self.client];
    [self.state forget];
    XCTAssertFalse([self.state isCurrentForString:@"ni" selectionRange:NSMakeRange(2, 0) client:self.client]);
}

// The recorded string is copied, so a caller that keeps appending to a mutable
// buffer cannot rewrite what was already sent.
- (void)testRecordedStringIsCopied {
    NSMutableString *buffer = [NSMutableString stringWithString:@"ni"];
    [self.state recordString:buffer selectionRange:NSMakeRange(2, 0) client:self.client];
    [buffer appendString:@"hao"];
    XCTAssertTrue([self.state isCurrentForString:@"ni" selectionRange:NSMakeRange(2, 0) client:self.client]);
    XCTAssertFalse([self.state isCurrentForString:@"nihao" selectionRange:NSMakeRange(2, 0) client:self.client]);
}

// Holding the client alive just to answer "did we already send this?" would
// keep a text view-owned object around after it is gone.
- (void)testClientIsNotRetained {
    __weak id weakClient = nil;
    @autoreleasepool {
        NSObject *client = [[NSObject alloc] init];
        weakClient = client;
        [self.state recordString:@"ni" selectionRange:NSMakeRange(2, 0) client:client];
        XCTAssertNotNil(weakClient);
    }
    XCTAssertNil(weakClient, @"MarkedTextState must not keep the client alive");
}

@end
