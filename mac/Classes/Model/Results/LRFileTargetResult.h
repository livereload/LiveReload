
#import "LRTarget.h"


@class LRProjectFile;


@interface LRFileTargetResult : LRTarget

- (instancetype)initWithAction:(Action *)action sourceFile:(LRProjectFile *)sourceFile;

@property (nonatomic, readonly) LRProjectFile *sourceFile;

@end
