
#import <Foundation/Foundation.h>


@interface NSArray (Substitutions)

- (NSArray *)arrayBySubstitutingValuesFromDictionary:(NSDictionary *)info;

@end


@interface NSString (Substitutions)

- (NSString *)stringBySubstitutingValuesFromDictionary:(NSDictionary *)info;

@end
