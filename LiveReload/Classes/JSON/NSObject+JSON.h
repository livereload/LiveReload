#import <Foundation/Foundation.h>

@interface NSObject (NSObject_SBJsonWriting)

- (NSString *)JSONRepresentation;

@end

@interface NSString (NSString_SBJsonParsing)

- (id)JSONValue;

@end
