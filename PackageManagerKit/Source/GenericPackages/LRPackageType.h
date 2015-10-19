
#import <Foundation/Foundation.h>


@class LRPackageContainer;
@class LRVersionSpace;

NS_ASSUME_NONNULL_BEGIN


@interface LRPackageType : NSObject

@property(nonatomic, readonly) NSString *name;
@property(nonatomic, readonly, nullable) NSString *bundledPackagesFolderName;
@property(nonatomic, readonly) LRVersionSpace *versionSpace;

- (void)addPackageContainer:(LRPackageContainer *)container;
- (void)removePackageContainer:(LRPackageContainer *)container;

@property(nonatomic, readonly) NSArray<LRPackageContainer *> *containers;

- (LRPackageContainer *)packageContainerAtFolderURL:(NSURL *)folderURL;

- (NSString *)identifierOfPackageNamed:(NSString *)packageName;

@end


NS_ASSUME_NONNULL_END
