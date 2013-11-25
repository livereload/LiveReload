
#import "LRManifestBasedObject.h"


@class LRPackageReference;


@interface LRManifestLayer : LRManifestBasedObject

+ (NSDictionary *)manifestByMergingLayers:(NSArray *)layers;

@property(nonatomic, readonly) NSArray *packageReferences;  // parsed by the layers to seed the package version detection system

@end
