//
//  EDSemverEqualTo.m
//  semver
//
//  Created by Andrew Sliwinski on 7/4/13.
//  Copyright (c) 2013 Andrew Sliwinski. All rights reserved.
//

#import "EDSemverEqualTo.h"

@implementation EDSemverEqualTo

- (void)testEqualTo
{
    NSArray *eq = @[
        @"1.2.3", @"v1.2.3",
        @"1.2.3", @"=1.2.3",
        @"1.2.3", @"v 1.2.3",
        @"1.2.3", @"= 1.2.3",
        @"1.2.3", @" v1.2.3",
        @"1.2.3", @" =1.2.3",
        @"1.2.3", @" v 1.2.3",
        @"1.2.3", @" = 1.2.3",
        @"1.2.3-0", @"v1.2.3-0",
        @"1.2.3-0", @"=1.2.3-0",
        @"1.2.3-0", @"v 1.2.3-0",
        @"1.2.3-0", @"= 1.2.3-0",
        @"1.2.3-0", @" v1.2.3-0",
        @"1.2.3-0", @" =1.2.3-0",
        @"1.2.3-0", @" v 1.2.3-0",
        @"1.2.3-0", @" = 1.2.3-0",
        @"1.2.3-1", @"v1.2.3-1",
        @"1.2.3-1", @"=1.2.3-1",
        @"1.2.3-1", @"v 1.2.3-1",
        @"1.2.3-1", @"= 1.2.3-1",
        @"1.2.3-1", @" v1.2.3-1",
        @"1.2.3-1", @" =1.2.3-1",
        @"1.2.3-1", @" v 1.2.3-1",
        @"1.2.3-1", @" = 1.2.3-1",
        @"1.2.3-beta", @"v1.2.3-beta",
        @"1.2.3-beta", @"=1.2.3-beta",
        @"1.2.3-beta", @"v 1.2.3-beta",
        @"1.2.3-beta", @"= 1.2.3-beta",
        @"1.2.3-beta", @" v1.2.3-beta",
        @"1.2.3-beta", @" =1.2.3-beta",
        @"1.2.3-beta", @" v 1.2.3-beta",
        @"1.2.3-beta", @" = 1.2.3-beta",
        @"1.2.3-beta+build", @" = 1.2.3-beta+otherbuild",
        @"1.2.3+build", @" = 1.2.3+otherbuild",
        @"1.2.3-beta+build", @"1.2.3-beta+otherbuild",
        @"1.2.3+build", @"1.2.3+otherbuild",
        @"  v1.2.3+build", @"1.2.3+otherbuild"
    ];
    
    for (NSUInteger i = 0; i < [eq count]; i+=2) {
        EDSemver *left = [[EDSemver alloc] initWithString:[eq objectAtIndex:i]];
        EDSemver *right = [[EDSemver alloc] initWithString:[eq objectAtIndex:i+1]];
        STAssertTrue([left isEqualTo:right], EQUAL_DESC);
    }
}

- (void)testNotEqualTo
{
    NSArray *eq = @[
        @"1.0.0", @"1.0.1",
        @"1.2", @"1.2.1"
    ];
    
    for (NSUInteger i = 0; i < [eq count]; i+=2) {
        EDSemver *left = [[EDSemver alloc] initWithString:[eq objectAtIndex:i]];
        EDSemver *right = [[EDSemver alloc] initWithString:[eq objectAtIndex:i+1]];
        STAssertFalse([left isEqualTo:right], EQUAL_DESC);
    }
}

@end
