
#import <Foundation/Foundation.h>


@interface NSAttributedString (ATAttributedStringAdditions)

+ (NSAttributedString *)AT_attributedStringWithPrimaryString:(NSString *)primaryString secondaryString:(NSString *)secondaryString primaryStyle:(NSDictionary *)primaryStyle secondaryStyle:(NSDictionary *)secondaryStyle;

@end
