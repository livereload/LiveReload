
#import <Foundation/Foundation.h>
#import "RegexKitLite.h"

@interface NSString (SmartRegexpCaptures)

- (NSDictionary *)dictionaryByMatchingWithRegexp:(NSString *)regexp withSmartSubstitutions:(NSDictionary *)substitutions options:(RKLRegexOptions)options;

@end
