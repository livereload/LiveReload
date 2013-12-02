
#import "LRPackageContainer.h"


@interface GemPackageContainer : LRPackageContainer

- (instancetype)initWithPackageType:(LRPackageType *)packageType folderURL:(NSURL *)folderURL;

@property(nonatomic, readonly) NSURL *folderURL;

@end
