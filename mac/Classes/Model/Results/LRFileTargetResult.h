
#import "LRTargetResult.h"


@class LRProjectFile;


@interface LRFileTargetResult : LRTargetResult

- (instancetype)initWithAction:(Action *)action sourceFile:(LRProjectFile *)sourceFile;

@property (nonatomic, readonly) LRProjectFile *sourceFile;

@end
