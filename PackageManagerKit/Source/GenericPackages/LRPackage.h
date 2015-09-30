
#import <Foundation/Foundation.h>


@class LRVersion;
@class LRPackageContainer;


@interface LRPackage : NSObject

- (instancetype)initWithName:(NSString *)name version:(LRVersion *)version container:(LRPackageContainer *)container sourceFolderURL:(NSURL *)sourceFolderURL;

@property(nonatomic, readonly) NSString *name;
@property(nonatomic, readonly) LRVersion *version;
@property(nonatomic, readonly, weak) LRPackageContainer *container;
@property(nonatomic, readonly) NSURL *sourceFolderURL;

@property(nonatomic, readonly) NSString *identifier;  // type:name
@property(nonatomic, readonly) NSString *identifierIncludingVersion;  // type:name:version

@end
