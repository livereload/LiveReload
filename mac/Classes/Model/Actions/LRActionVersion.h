
#import <Foundation/Foundation.h>


@class ActionType;
@class LRActionManifest;
@class LRPackageSet;


@interface LRActionVersion : NSObject

- (instancetype)initWithType:(ActionType *)type manifest:(LRActionManifest *)manifest packageSet:(LRPackageSet *)packageSet;

@property(nonatomic, readonly) ActionType *type;
@property(nonatomic, readonly) LRActionManifest *manifest;
@property(nonatomic, readonly) LRPackageSet *packageSet;

@end
