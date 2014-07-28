
#import <Foundation/Foundation.h>
@import LRActionKit;


@class Rule;
@class LRManifestLayer;


// specific rule types can derive from this, but in most cases
// the best choice is to just add all sorts of info here
@interface LRActionManifest : LRManifestBasedObject

- (instancetype)initWithLayers:(NSArray *)layers;

@property(nonatomic, readonly, copy) NSArray *layers;

@property(nonatomic, copy) NSString *identifier;
@property(nonatomic, copy) NSString *name;

@property(nonatomic, strong) NSArray *optionSpecs;
- (NSArray *)createOptionsWithAction:(Rule *)rule;

@property(nonatomic, copy) NSArray *errorSpecs;
@property(nonatomic, copy) NSArray *warningSpecs;
@property(nonatomic, copy) NSArray *commandLineSpec;

@property(nonatomic, readonly) NSString *changeLogSummary;

// override point
- (void)initializeActionManifest;

@end
