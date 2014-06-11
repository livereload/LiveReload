
#import <Foundation/Foundation.h>


typedef NS_OPTIONS(NSUInteger, LRVersionTag) {
    LRVersionTagUnknown = 0,
    LRVersionTagDeprecated = 0x01,
    LRVersionTagStable = 0x02,
    LRVersionTagPrerelease = 0x04,
};


enum { LRVersionTagAll = LRVersionTagDeprecated | LRVersionTagStable | LRVersionTagPrerelease };
enum { LRVersionTagAllStable = LRVersionTagDeprecated | LRVersionTagStable };
