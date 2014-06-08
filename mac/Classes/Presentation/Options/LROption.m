
#import "Errors.h"
#import "LROption.h"
#import "LiveReload-Swift-x.h"


@implementation LROption

- (id)initWithManifest:(NSDictionary *)manifest action:(Action *)action errorSink:(id<LRManifestErrorSink>)errorSink {
    self = [super initWithManifest:manifest errorSink:errorSink];
    if (self) {
        _action = action;
        [self loadManifest];
    }
    return self;
}

- (id)copyWithAction:(Action *)action {
    return [[self.class alloc] initWithManifest:self.manifest action:action errorSink:self.errorSink];
}

- (void)renderInOptionsView:(LROptionsView *)optionsView {
}

- (NSString *)optionKeyForPresentedValue {
    return _identifier;
}

- (void)loadManifest {
    _identifier = self.manifest[@"id"];
    if (_identifier.length == 0)
        [self addErrorMessage:@"Missing id key"];

    _label = self.manifest[@"label"];
}

- (void)loadModelValues {
    if (!self.valid)
        return;
    [self setPresentedValue:self.effectiveValue];
}

- (void)saveModelValues {
    if (!self.valid)
        return;
    id value = [self presentedValue];
    if ([value isEqual:self.defaultValue])
        value = nil;
    self.modelValue = value;
}

- (void)presentedValueDidChange {
    [self saveModelValues];
}

- (id)defaultValue {
    return nil;
}

- (id)presentedValue {
    return nil;
}

- (void)setPresentedValue:(id)value {
}

- (id)modelValue {
    return [self.action optionValueForKey:self.optionKeyForPresentedValue];
}

- (id)effectiveValue {
    return self.modelValue ?: self.defaultValue;
}

- (void)setModelValue:(id)value {
    [self.action setOptionValue:value forKey:self.optionKeyForPresentedValue];
}

@end
