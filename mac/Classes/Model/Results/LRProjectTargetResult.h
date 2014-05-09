
#import "LRTargetResult.h"


@interface LRProjectTargetResult : LRTargetResult

- (instancetype)initWithAction:(Action *)action modifiedPaths:(NSSet *)modifiedPaths;

@property (nonatomic, copy, readonly) NSSet *modifiedPaths;

@end
