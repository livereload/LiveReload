
#import "Errors.h"
#import "LROption.h"
#import "Action.h"


@implementation LROption {
    NSMutableArray *_errors;
}

- (id)initWithOptionManifest:(NSDictionary *)manifest action:(Action *)action {
    self = [super init];
    if (self) {
        _manifest = [manifest copy];
        _action = action;
        _valid = YES;
        [self loadManifest];
    }
    return self;
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
    [self setPresentedValue:self.effectiveValue];
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

- (id)effectiveValue {
    return self.modelValue ?: self.defaultValue;
}

- (void)setModelValue:(id)value {
    [self.action setOptionValue:value forKey:self.optionKeyForPresentedValue];
}

- (void)addErrorMessage:(NSString *)message {
    _valid = NO;
    [_errors addObject:[NSError errorWithDomain:LRErrorDomain code:LRErrorInvalidManifest userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"%@ in option %@", message, self.manifest]}]];
}

- (NSArray *)errors {
    return [_errors copy];
}

@end
