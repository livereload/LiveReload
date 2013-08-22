
#import "ATAttributedStringAdditions.h"


@implementation NSAttributedString (ATAttributedStringAdditions)

+ (NSAttributedString *)AT_attributedStringWithPrimaryString:(NSString *)primaryString secondaryString:(NSString *)secondaryString primaryStyle:(NSDictionary *)primaryStyle secondaryStyle:(NSDictionary *)secondaryStyle {
    NSMutableAttributedString *resultAS = [NSMutableAttributedString new];
    [resultAS appendAttributedString:[[NSAttributedString alloc] initWithString:primaryString attributes:primaryStyle]];
    [resultAS appendAttributedString:[[NSAttributedString alloc] initWithString:secondaryString attributes:secondaryStyle]];
    return [[NSAttributedString alloc] initWithAttributedString:resultAS];
}

@end
