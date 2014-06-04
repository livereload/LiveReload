
#import "LRTarget.h"


@interface LRProjectTarget : LRTarget

- (instancetype)initWithAction:(Action *)action modifiedFiles:(NSArray *)modifiedFiles;

@property (nonatomic, copy, readonly) NSArray *modifiedFiles;

@end
