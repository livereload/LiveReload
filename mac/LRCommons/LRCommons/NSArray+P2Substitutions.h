
#import <Foundation/Foundation.h>


@interface NSArray (P2Substitutions)

- (NSArray *)p2_arrayBySubstitutingValuesFromDictionary:(NSDictionary *)info;

@end


@interface NSString (P2Substitutions)

- (NSString *)p2_stringBySubstitutingValuesFromDictionary:(NSDictionary *)info;

@end
