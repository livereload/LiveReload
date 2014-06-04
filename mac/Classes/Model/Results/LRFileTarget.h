
#import "LRTarget.h"


@class LRProjectFile;


@interface LRFileTarget : LRTarget

- (instancetype)initWithAction:(Action *)action sourceFile:(LRProjectFile *)sourceFile;

@property (nonatomic, readonly) LRProjectFile *sourceFile;

@end
