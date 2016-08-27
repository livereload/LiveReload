#import <Foundation/Foundation.h>

@implementation NSObject (NSObject_SBJsonWriting)

- (NSString *)JSONRepresentation {
    NSData *data = [NSJSONSerialization dataWithJSONObject:self options:0 error:NULL];
    if (data) {
        return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    }
    return nil;
}

@end



@implementation NSString (NSString_SBJsonParsing)

- (id)JSONValue {
    return [NSJSONSerialization JSONObjectWithData:[self dataUsingEncoding:NSUTF8StringEncoding] options:0 error:NULL];
}

@end
