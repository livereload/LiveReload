
#import "LRTargetResult.h"


@class LRFile2;


@interface LRFileTargetResult : LRTargetResult

- (instancetype)initWithAction:(Action *)action sourceFile:(LRFile2 *)sourceFile;

@property (nonatomic, readonly) LRFile2 *sourceFile;

@end
