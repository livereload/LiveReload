//
//  NSString+SeparatingIntoComponents.m
//
//  Created by Matt Gallagher on 4/05/09.
//  Copyright 2009 Matt Gallagher. All rights reserved.
//
//  Permission is given to use this source code file, free of charge, in any
//  project, commercial or otherwise, entirely at your risk, with the condition
//  that any redistribution (in part or whole) of source code must retain
//  this copyright and permission notice. Attribution in compiled projects is
//  appreciated but not required.
//

#import "NSString+SeparatingIntoComponents.h"

@implementation NSString (SeparatingIntoComponents)

- (NSArray *)arrayBySeparatingIntoParagraphs
{
    NSUInteger length = [self length];
    NSUInteger paraStart = 0;
    NSUInteger paraEnd = 0;
    NSUInteger contentsEnd = 0;
    NSMutableArray *array = [NSMutableArray array];
    NSRange currentRange;
    while (paraEnd < length)
    {
        [self
            getParagraphStart:&paraStart
            end:&paraEnd
            contentsEnd:&contentsEnd
            forRange:NSMakeRange(paraEnd, 0)];
        currentRange = NSMakeRange(paraStart, contentsEnd - paraStart);
        [array addObject:[self substringWithRange:currentRange]];
    }
    return array;
}

- (NSArray *)tokensSeparatedByCharactersInSet:(NSCharacterSet *)separator
{
    NSScanner *scanner = [NSScanner scannerWithString:self];
    NSMutableArray *array = [NSMutableArray array];
    while (![scanner isAtEnd])
    {
        [scanner scanCharactersFromSet:separator intoString:nil];

        NSString *component;
        if ([scanner scanUpToCharactersFromSet:separator intoString:&component])
        {
            [array addObject:component];
        }
    }
    return array;
}

@end
