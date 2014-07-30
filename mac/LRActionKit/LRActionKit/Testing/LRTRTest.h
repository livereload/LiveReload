@import Foundation;
#import "LRTRGlobals.h"


@interface LRTRTest : NSObject

- (instancetype)initWithName:(NSString *)name status:(LRTRTestStatus)status;

@property(nonatomic, copy) NSString *name;
@property(nonatomic) LRTRTestStatus status;

- (void)appendExtraOutput:(NSString *)output;

@end
