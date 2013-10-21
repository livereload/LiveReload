
#import "LROption.h"

@interface LROption (Factory)

+ (LROption *)optionWithSpec:(NSDictionary *)spec action:(Action *)action;

@end
