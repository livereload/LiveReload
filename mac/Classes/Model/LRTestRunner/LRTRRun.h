
#import <Foundation/Foundation.h>
#import "LRTRProtocolParser.h"


@interface LRTRRun : NSObject <LRTRProtocolParserDelegate>

@property(nonatomic, readonly) NSArray *tests;

@end
