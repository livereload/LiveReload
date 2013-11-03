
#import "LRPackageContainer.h"

@interface NpmPackageContainer : LRPackageContainer

- (instancetype)initWithPackageType:(LRPackageType *)packageType folderURL:(NSURL *)folderURL;

@property(nonatomic, readonly) NSURL *folderURL;

@end
