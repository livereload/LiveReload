
#import <Foundation/Foundation.h>
@import LRActionKit;


@class LROptionsView;
@class Rule;


// app model layer (a blend of model and controller)
@interface LROption : LRManifestBasedObject

- (id)initWithManifest:(NSDictionary *)manifest rule:(Rule *)rule errorSink:(id<LRManifestErrorSink>)errorSink;

- (id)copyWithAction:(Rule *)rule;

@property(nonatomic, copy) NSString *identifier;
@property(nonatomic, readonly, strong) Rule *rule;

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
@property(nonatomic, strong, readonly) id effectiveValue; // modelValue ?: defaultValue

@property(nonatomic, readonly) NSArray *commandLineArguments;

@end
