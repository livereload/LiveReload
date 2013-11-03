//
//  EDSemverValid.m
//  semver
//
//  Created by Andrew Sliwinski on 7/4/13.
//  Copyright (c) 2013 Andrew Sliwinski. All rights reserved.
//

#import "EDSemverValid.h"

@interface EDSemverValid ()
@property NSArray *validList;
@property NSArray *invalidList;
@end

@implementation EDSemverValid

@synthesize validList = _validList;
@synthesize invalidList = _invalidList;

- (void)setUp
{
    [super setUp];
    
    _validList = @[@"1.2.3", @"v1.2.3", @"1.2.3-foo", @"1.0.0-alpha", @"1.0-alpha", @"1-alpha", @"   1.2.3", @"1.2.3 "];
    _invalidList = @[@"", @"z1.2.3", @"1.2.3foo", @"alpha"];
}

- (void)testValidTrue
{
    for (NSUInteger i = 0; i < [_validList count]; i++) {
        EDSemver *ver = [[EDSemver alloc] initWithString:[_validList objectAtIndex:i]];
        STAssertTrue([ver isValid], VALID_DESC);
    }
}

- (void)testValidFalse
{
    for (NSUInteger i = 0; i < [_invalidList count]; i++) {
        EDSemver *ver = [[EDSemver alloc] initWithString:[_invalidList objectAtIndex:i]];
        STAssertFalse([ver isValid], VALID_DESC);
    }
}

@end
