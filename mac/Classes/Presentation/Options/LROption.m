
#import "LROption.h"
#import "Action.h"


@implementation LROption

- (id)initWithOptionManifest:(NSDictionary *)manifest {
    self = [super init];
    if (self) {
        _manifest = [manifest copy];
        _valid = YES;
        [self loadManifest];
    }
    return self;
}

- (void)setAction:(Action *)action {
    if (_action != action) {
        _action = action;
        [self loadModelValues];
    }
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
    if (!_valid)
        return;
    id value = self.modelValue ?: self.defaultValue;
    [self setPresentedValue:value];
}

- (void)saveModelValues {
    if (!_valid)
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

- (void)setModelValue:(id)value {
    [self.action setOptionValue:value forKey:self.optionKeyForPresentedValue];
}

- (void)addErrorMessage:(NSString *)message {
    _valid = NO;
    NSLog(@"Error: %@ in option %@", message, self.manifest);
}

@end
