//
//  LRCommonsTests.m
//  LRCommonsTests
//
//  Created by Andrey Tarantsov on 27.07.2014.
//  Copyright (c) 2014 livereload. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <XCTest/XCTest.h>
@import LRCommons;

@interface LRCommonsTests : XCTestCase

@end

@implementation LRCommonsTests

- (void)testVersionString {
    XCTAssertEqualObjects(NSStringFromATVersion(ATVersionMake(1, 2, 3)), @"1.2.3");
}

@end
