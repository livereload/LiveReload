
#import "NSString+ATProperURLEncoding.h"

@implementation NSString (ATProperURLEncoding)

static const char *HEX = "0123456789ABCDEF";

- (NSString *)stringByApplyingURLEncoding {
    return [self stringByEscapingURLComponent];
}

// see:
// http://stackoverflow.com/questions/3423545/objective-c-iphone-percent-encode-a-string
// http://en.wikipedia.org/wiki/Percent-encoding
- (NSString *)stringByEscapingURLComponent {
    const char *source = [self UTF8String];
    char *output = malloc(strlen(source) * 3 + 1);  // use heap in case the string is very long
    char *pout = output;
    for (const char *psrc = source; *psrc; psrc++) {
        unsigned char ch = *psrc;
        if (ch == '.' || ch == '-' || ch == '_' || ch == '~' || (ch >= 'a' && ch <= 'z') || (ch >= 'A' && ch <= 'Z') || (ch >= '0' && ch <= '9')) {
            *pout++ = ch;
        } else {
            *pout++ = '%';
            *pout++ = HEX[(ch >> 4) & 0xF];
            *pout++ = HEX[ch & 0xF];
        }
    }
    *pout = 0;

    NSString *result = [NSString stringWithUTF8String:output];
    free(output);
    return result;
    //    return (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(NULL, (__bridge CFStringRef)self, NULL, (CFStringRef)@"!*'\"();:@&=+$,/?%#[]% ", kCFStringEncodingUTF8));
}

- (NSString *)stringByUnescapingURLComponent {
    return [self stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
}

- (void)enumerateURLQueryComponentsUsingBlock:(void (^)(NSString *key, NSString *value))block {
    for(NSString *pair in [self componentsSeparatedByString:@"&"]) {
        NSRange range = [pair rangeOfString:@"="];
        if (range.location == NSNotFound) {
            NSString *key = [pair stringByUnescapingURLComponent];
            block(key, @"");
        } else {
            NSString *key = [[pair substringToIndex:range.location] stringByUnescapingURLComponent];
            NSString *value = [[pair substringFromIndex:range.location + range.length] stringByUnescapingURLComponent];
            block(key, value);
        }
    }
}

- (NSDictionary *)dictionaryByParsingURLQueryComponents {
    NSMutableDictionary *result = [NSMutableDictionary dictionary];
    [self enumerateURLQueryComponentsUsingBlock:^(NSString *key, NSString *value) {
        result[key] = value;
    }];
    return result;
}

@end
