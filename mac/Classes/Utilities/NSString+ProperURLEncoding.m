
#import "NSString+ProperURLEncoding.h"

@implementation NSString (ProperURLEncoding)

- (NSString *)stringByApplyingURLEncoding {
    return (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(NULL, (__bridge CFStringRef)self, NULL, (CFStringRef)@"!*'\"();:@&=+$,/?%#[]% ", kCFStringEncodingUTF8));
}

@end
