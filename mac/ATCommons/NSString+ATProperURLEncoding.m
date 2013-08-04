
#import "NSString+ATProperURLEncoding.h"

@implementation NSString (ATProperURLEncoding)

- (NSString *)stringByApplyingURLEncoding {
    return (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(NULL, (__bridge CFStringRef)self, NULL, (CFStringRef)@"!*'\"();:@&=+$,/?%#[]% ", kCFStringEncodingUTF8));
}

@end
