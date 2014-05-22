
#import "LRTargetResult.h"


@interface LRProjectTargetResult : LRTargetResult

- (instancetype)initWithAction:(Action *)action modifiedFiles:(NSArray *)modifiedFiles;

@property (nonatomic, copy, readonly) NSArray *modifiedFiles;

@end
