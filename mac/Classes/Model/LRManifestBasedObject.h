
#import <Foundation/Foundation.h>


@interface LRManifestBasedObject : NSObject

- (instancetype)initWithManifest:(NSDictionary *)manifest;

@property(nonatomic, readonly) NSDictionary *manifest;

@end
