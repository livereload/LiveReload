
#import <Foundation/Foundation.h>


typedef enum {
    LRVersionTagUnknown = 0,
    LRVersionTagDeprecated = 0x01,
    LRVersionTagStable = 0x02,
    LRVersionTagPrerelease = 0x04,
} LRVersionTag;


enum { LRVersionTagAll = LRVersionTagDeprecated | LRVersionTagStable | LRVersionTagPrerelease };
enum { LRVersionTagAllStable = LRVersionTagDeprecated | LRVersionTagStable };
