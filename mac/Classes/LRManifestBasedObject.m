
#import "LRManifestBasedObject.h"
#import "Errors.h"


@implementation LRManifestBasedObject {
    NSMutableArray *_errors;
}

- (instancetype)initWithManifest:(NSDictionary *)manifest errorSink:(id<LRManifestErrorSink>)errorSink {
    self = [super init];
    if (self) {
        _errorSink = errorSink;
        _manifest = [manifest copy];
        _valid = YES;
    }
    return self;
}

- (void)addErrorMessage:(NSString *)message {
    message = [NSString stringWithFormat:@"%@ in %@ %@", message, NSStringFromClass(self.class), self.manifest];

    _valid = NO;
    if (!_errors) {
        _errors = [NSMutableArray new];
    }
    [_errors addObject:[NSError errorWithDomain:LRErrorDomain code:LRErrorInvalidManifest userInfo:@{NSLocalizedDescriptionKey:message}]];

    if (_errorSink) {
        [_errorSink addErrorMessage:message];
    }
}

- (NSArray *)errors {
    return [_errors copy];
}

@end
