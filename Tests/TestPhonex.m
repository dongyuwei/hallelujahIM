#import <JavaScriptCore/JavaScriptCore.h>
#import <XCTest/XCTest.h>

@interface TestPhonex : XCTestCase
@property JSContext *context;
@property JSValue *phonexFunc;
@end

@implementation TestPhonex

- (void)setUp {
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    NSString *scriptPath = [bundle pathForResource:@"phonex" ofType:@"js"];
    NSString *scriptString = [NSString stringWithContentsOfFile:scriptPath encoding:NSUTF8StringEncoding error:nil];

    self.context = [[JSContext alloc] init];

    [self.context evaluateScript:scriptString];
    self.phonexFunc = self.context[@"phonex"];
}

- (void)tearDown {
}

- (void)testJavaScriptCoreBasicFunction {
    [self.context evaluateScript:@"function greet(name){ return 'Hello, ' + name; }"];
    JSValue *function = self.context[@"greet"];
    JSValue *result = [function callWithArguments:@[ @"World" ]];
    XCTAssertTrue([[result toString] isEqualToString:@"Hello, World"]);
}

- (void)testPhonexEncode {
    JSValue *phonexFunc = self.phonexFunc;
    XCTAssertTrue([[[phonexFunc callWithArguments:@[ @"test" ]] toString] isEqualToString:@"T23"]);

    XCTAssertTrue([[[phonexFunc callWithArguments:@[ @"courage" ]] toString]
        isEqualToString:[[phonexFunc callWithArguments:@[ @"cerrage" ]] toString]]);

    XCTAssertTrue([[[phonexFunc callWithArguments:@[ @"kerrage" ]] toString]
        isEqualToString:[[phonexFunc callWithArguments:@[ @"cerrage" ]] toString]]);

    XCTAssertTrue([[[phonexFunc callWithArguments:@[ @"inderpendent" ]] toString]
        isEqualToString:[[phonexFunc callWithArguments:@[ @"independent" ]] toString]]);

    XCTAssertTrue([[[phonexFunc callWithArguments:@[ @"aosome" ]] toString]
        isEqualToString:[[phonexFunc callWithArguments:@[ @"awesome" ]] toString]]);

    XCTAssertTrue([[[phonexFunc callWithArguments:@[ @"ausome" ]] toString]
        isEqualToString:[[phonexFunc callWithArguments:@[ @"awesome" ]] toString]]);
}

- (void)testPerformanceExample {
    [self measureBlock:^{
//        [self testPhonexEncode];
    }];
}

@end
