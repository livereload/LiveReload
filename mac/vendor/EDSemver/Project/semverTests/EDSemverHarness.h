//
//  EDSemverHarness.h
//  semver
//
//  Created by Andrew Sliwinski on 7/4/13.
//  Copyright (c) 2013 Andrew Sliwinski. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>
#import "EDSemver.h"

#define MAJOR_DESC @"Major equals expected value."
#define MINOR_DESC @"Minor equals expected value."
#define PATCH_DESC @"Patch equals expected value."
#define PRERELEASE_DESC @"Prerelease equals expected value."
#define BUILD_DESC @"Build equals expected value."
#define VALID_DESC @"Validity is of expected value."
#define EQUAL_DESC @"Equality is of expected value."
#define COMP_DESC @"Comparator is of expected value."