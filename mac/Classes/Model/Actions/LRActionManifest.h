
#import <Foundation/Foundation.h>
#import "LRManifestBasedObject.h"


@class Action;
@class LRManifestLayer;


// specific action types can derive from this, but in most cases
// the best choice is to just add all sorts of info here
@interface LRActionManifest : LRManifestBasedObject

- (instancetype)initWithLayers:(NSArray *)layers;

@property(nonatomic, readonly, copy) NSArray *layers;

@property(nonatomic, copy) NSString *identifier;
@property(nonatomic, copy) NSString *name;

@property(nonatomic, strong) NSArray *optionSpecs;
- (NSArray *)createOptionsWithAction:(Action *)action;

@property(nonatomic, copy) NSArray *errorSpecs;

// override point
- (void)initializeActionManifest;

@end
