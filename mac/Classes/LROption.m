
#import "Errors.h"
#import "LROption.h"
#import "LiveReload-Swift-x.h"


@implementation LROption

- (id)initWithManifest:(NSDictionary *)manifest rule:(Rule *)rule errorSink:(id<LRManifestErrorSink>)errorSink {
    self = [super initWithManifest:manifest errorSink:errorSink];
    if (self) {
        _rule = rule;
        [self loadManifest];
    }
    return self;
}

- (id)copyWithAction:(Rule *)rule {
    return [[self.class alloc] initWithManifest:self.manifest rule:rule errorSink:self.errorSink];
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
    return [self.rule optionValueForKey:self.optionKeyForPresentedValue];
}

- (id)effectiveValue {
    return self.modelValue ?: self.defaultValue;
}

- (void)setModelValue:(id)value {
    [self.rule setOptionValue:value forKey:self.optionKeyForPresentedValue];
}

- (NSArray *)commandLineArguments {
    return @[]; // handled elsewhere
}

@end
