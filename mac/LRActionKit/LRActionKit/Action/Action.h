@import Foundation;
#import "ActionKitGlobals.h"
#import "LRManifestBasedObject.h"


@class Plugin;
@class Rule;
@class LRActionVersion;
@class LRVersionSpace;
@class ATPathSpec;
@class ProjectFile;


@interface Action : LRManifestBasedObject

- (instancetype)initWithManifest:(NSDictionary *)manifest plugin:(Plugin *)plugin;

@property(nonatomic, strong) Plugin *plugin;
@property(nonatomic, assign) Class actionClass;
@property(nonatomic, assign) Class rowClass;

@property(nonatomic) ActionKind kind;
@property(nonatomic, copy) NSString *identifier;
@property(nonatomic, copy) NSString *name;

@property(nonatomic, readonly, copy) NSArray *packageConfigurations;
@property(nonatomic, readonly, copy) NSArray *manifestLayers;

@property(nonatomic, readonly) LRVersionSpace *primaryVersionSpace;

@property(nonatomic, readonly) ATPathSpec *combinedIntrinsicInputPathSpec;

- (void)initializeWithOptions;

- (NSString *)fakeChangeDestinationNameForSourceFile:(ProjectFile *)file;

@end
