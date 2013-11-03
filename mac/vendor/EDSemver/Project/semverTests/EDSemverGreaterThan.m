//
//  EDSemverGreaterThan.m
//  semver
//
//  Created by Andrew Sliwinski on 7/7/13.
//  Copyright (c) 2013 Andrew Sliwinski. All rights reserved.
//

#import "EDSemverGreaterThan.h"

@implementation EDSemverGreaterThan

- (void)testGreaterThan
{
    NSArray *eq = @[
        @"0.0.0", @"0.0.0-foo",
        @"0.0.1", @"0.0.0",
        @"1.0.0", @"0.9.9",
        @"0.10.0", @"0.9.0",
        @"0.99.0", @"0.10.0",
        @"2.0.0", @"1.2.3",
        @"v0.0.0", @"0.0.0-foo",
        @"v0.0.1", @"0.0.0",
        @"v1.0.0", @"0.9.9",
        @"v0.10.0", @"0.9.0",
        @"v0.99.0", @"0.10.0",
        @"v2.0.0", @"1.2.3",
        @"0.0.0", @"v0.0.0-foo",
        @"0.0.1", @"v0.0.0",
        @"1.0.0", @"v0.9.9",
        @"0.10.0", @"v0.9.0",
        @"0.99.0", @"v0.10.0",
        @"2.0.0", @"v1.2.3",
        @"1.2.3", @"1.2.3-asdf",
        @"1.2.3", @"1.2.3-4",
        @"1.2.3", @"1.2.3-4-foo",
        @"1.2.3-5-foo", @"1.2.3-5",
        @"1.2.3-5", @"1.2.3-4",
        @"3.0.0", @"2.7.2+asdf"
    ];
    
    for (NSUInteger i = 0; i < [eq count]; i+=2) {
        EDSemver *left = [[EDSemver alloc] initWithString:[eq objectAtIndex:i]];
        EDSemver *right = [[EDSemver alloc] initWithString:[eq objectAtIndex:i+1]];
        STAssertEquals([left compare:right], NSOrderedDescending, [NSString stringWithFormat:@"Expected %@ to be greater than %@", left, right]);
    }
}

@end
