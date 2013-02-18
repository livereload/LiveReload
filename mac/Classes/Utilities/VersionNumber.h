
#import <Foundation/Foundation.h>

typedef NSUInteger VersionNumber;

enum { VersionNumberFuture = 999999 };

VersionNumber VersionNumberFromNSString(NSString *string);
