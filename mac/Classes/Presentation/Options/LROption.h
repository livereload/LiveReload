
#import <Foundation/Foundation.h>


@class LROptionsView;
@class Action;


// app model layer (a blend of model and controller)
@interface LROption : NSObject

- (id)initWithOptionManifest:(NSDictionary *)manifest;

@property(nonatomic, readonly) BOOL valid;

@property(nonatomic, copy) NSString *identifier;
@property(nonatomic, copy) NSDictionary *manifest;
@property(nonatomic, retain) Action *action;

- (void)renderInOptionsView:(LROptionsView *)optionsView;

// override points
- (void)loadManifest;
- (void)loadModelValues;
- (void)saveModelValues;

- (void)addErrorMessage:(NSString *)message;

@end
