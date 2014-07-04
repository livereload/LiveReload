
#import <Foundation/Foundation.h>


@class ActionType;
@class LRActionManifest;
@class LRPackageSet;
@class LRVersion;


@interface LRActionVersion : NSObject

- (instancetype)initWithType:(ActionType *)type manifest:(LRActionManifest *)manifest packageSet:(LRPackageSet *)packageSet;

@property(nonatomic, readonly) ActionType *type;
@property(nonatomic, readonly) LRActionManifest *manifest;
@property(nonatomic, readonly) LRPackageSet *packageSet;

@property(nonatomic, readonly) LRVersion *primaryVersion;

@end
