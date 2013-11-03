//
//  EDSemverParse.m
//  semver
//
//  Created by Andrew Sliwinski on 7/4/13.
//  Copyright (c) 2013 Andrew Sliwinski. All rights reserved.
//

#import "EDSemverParse.h"

@implementation EDSemverParse

- (void)testParseMajor
{
    EDSemver *ver = [[EDSemver alloc] initWithString:@"1.0.0"];
    STAssertEquals(1, [ver major], MAJOR_DESC);
    STAssertEquals(0, [ver minor], MINOR_DESC);
    STAssertEquals(0, [ver patch], PATCH_DESC);
    STAssertEqualObjects(@"", [ver prerelease], PRERELEASE_DESC);
    STAssertEqualObjects(@"", [ver build], BUILD_DESC);
}

- (void)testParseMinor
{
    EDSemver *ver = [[EDSemver alloc] initWithString:@"0.1.0"];
    STAssertEquals(0, [ver major], MAJOR_DESC);
    STAssertEquals(1, [ver minor], MINOR_DESC);
    STAssertEquals(0, [ver patch], PATCH_DESC);
    STAssertEqualObjects(@"", [ver prerelease], PRERELEASE_DESC);
    STAssertEqualObjects(@"", [ver build], BUILD_DESC);
}

- (void)testParsePatch
{
    EDSemver *ver = [[EDSemver alloc] initWithString:@"0.0.1"];
    STAssertEquals(0, [ver major], MAJOR_DESC);
    STAssertEquals(0, [ver minor], MINOR_DESC);
    STAssertEquals(1, [ver patch], PATCH_DESC);
    STAssertEqualObjects(@"", [ver prerelease], PRERELEASE_DESC);
    STAssertEqualObjects(@"", [ver build], BUILD_DESC);
}

- (void)testParsePrerelease
{
    EDSemver *ver = [[EDSemver alloc] initWithString:@"1.2.3-alpha"];
    STAssertEquals(1, [ver major], MAJOR_DESC);
    STAssertEquals(2, [ver minor], MINOR_DESC);
    STAssertEquals(3, [ver patch], PATCH_DESC);
    STAssertEqualObjects(@"alpha", [ver prerelease], PRERELEASE_DESC);
    STAssertEqualObjects(@"", [ver build], BUILD_DESC);
}

- (void)testParseBuild
{
    EDSemver *ver = [[EDSemver alloc] initWithString:@"1.2.3+1"];
    STAssertEquals(1, [ver major], MAJOR_DESC);
    STAssertEquals(2, [ver minor], MINOR_DESC);
    STAssertEquals(3, [ver patch], PATCH_DESC);
    STAssertEqualObjects(@"", [ver prerelease], PRERELEASE_DESC);
    STAssertEqualObjects(@"1", [ver build], BUILD_DESC);
}

- (void)testParseComplex
{
    EDSemver *ver = [[EDSemver alloc] initWithString:@"v1.2.23-alpha+1.833"];
    STAssertEquals(1, [ver major], MAJOR_DESC);
    STAssertEquals(2, [ver minor], MINOR_DESC);
    STAssertEquals(23, [ver patch], PATCH_DESC);
    STAssertEqualObjects(@"alpha", [ver prerelease], PRERELEASE_DESC);
    STAssertEqualObjects(@"1.833", [ver build], BUILD_DESC);
}

@end
