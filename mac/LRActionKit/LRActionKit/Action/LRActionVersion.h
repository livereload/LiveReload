@import Foundation;


@class Action;
@class LRActionManifest;
@class LRPackageSet;
@class LRVersion;


@interface LRActionVersion : NSObject

- (instancetype)initWithType:(Action *)type manifest:(LRActionManifest *)manifest packageSet:(LRPackageSet *)packageSet;

@property(nonatomic, readonly) Action *type;
@property(nonatomic, readonly) LRActionManifest *manifest;
@property(nonatomic, readonly) LRPackageSet *packageSet;

@property(nonatomic, readonly) LRVersion *primaryVersion;

@end
