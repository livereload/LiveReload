
#import <Foundation/Foundation.h>


@class LROptionsView;
@class Action;


// app model layer (a blend of model and controller)
@interface LROption : NSObject

- (id)initWithOptionManifest:(NSDictionary *)manifest action:(Action *)action;

@property(nonatomic, readonly) BOOL valid;

@property(nonatomic, copy) NSString *identifier;
@property(nonatomic, copy) NSDictionary *manifest;
@property(nonatomic, readonly, strong) Action *action;

@property(nonatomic, copy) NSString *label;  // courtesy for subclasses, usage is optional

- (void)renderInOptionsView:(LROptionsView *)optionsView;

- (void)loadManifest;
- (void)loadModelValues;
- (void)saveModelValues;

@property(nonatomic, readonly) NSString *optionKeyForPresentedValue;
@property(nonatomic, readonly) id defaultValue;

// used by default implementations of loadModelValues/saveModelValues
- (void)presentedValueDidChange;

@property(nonatomic, strong) id presentedValue;
@property(nonatomic, strong) id modelValue;
@property(nonatomic, strong) id effectiveValue; // modelValue ?: defaultValue

- (void)addErrorMessage:(NSString *)message;

@property(nonatomic, readonly) NSArray *commandLineArguments;

@end
