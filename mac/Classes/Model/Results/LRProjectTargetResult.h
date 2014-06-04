
#import "LRTarget.h"


@interface LRProjectTargetResult : LRTarget

- (instancetype)initWithAction:(Action *)action modifiedFiles:(NSArray *)modifiedFiles;

@property (nonatomic, copy, readonly) NSArray *modifiedFiles;

@end
