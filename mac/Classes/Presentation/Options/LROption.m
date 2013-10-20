
#import "LROption.h"


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

- (void)loadManifest {
    _identifier = self.manifest[@"id"];
    if (_identifier.length == 0)
        [self addErrorMessage:@"Missing id key"];
}
- (void)loadModelValues {
}
- (void)saveModelValues {
}

- (void)addErrorMessage:(NSString *)message {
    _valid = NO;
    NSLog(@"Error: %@ in option %@", message, self.manifest);
}

@end
