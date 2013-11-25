
#import <Foundation/Foundation.h>


@class LRPackageContainer;
@class LRVersionSpace;


@interface LRPackageType : NSObject

@property(nonatomic, readonly) NSString *name;
@property(nonatomic, readonly) NSString *bundledPackagesFolderName;
@property(nonatomic, readonly) LRVersionSpace *versionSpace;

- (void)addPackageContainer:(LRPackageContainer *)container;
- (void)removePackageContainer:(LRPackageContainer *)container;

@property(nonatomic, readonly) NSArray *containers;

- (LRPackageContainer *)packageContainerAtFolderURL:(NSURL *)folderURL;

- (NSString *)identifierOfPackageNamed:(NSString *)packageName;

@end
