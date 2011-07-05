//
//  NSString+SeparatingIntoComponents.h
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

#import <Cocoa/Cocoa.h>

@interface NSString (SeparatingIntoComponents)

- (NSArray *)arrayBySeparatingIntoParagraphs;
- (NSArray *)tokensSeparatedByCharactersInSet:(NSCharacterSet *)separator;

@end
