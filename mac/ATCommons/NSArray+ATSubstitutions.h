
#import <Foundation/Foundation.h>


@interface NSArray (ATSubstitutions)

- (NSArray *)arrayBySubstitutingValuesFromDictionary:(NSDictionary *)info;

@end


@interface NSString (ATSubstitutions)

- (NSString *)stringBySubstitutingValuesFromDictionary:(NSDictionary *)info;

@end
