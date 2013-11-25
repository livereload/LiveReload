
#import "LRChildErrorSink.h"


@implementation LRChildErrorSink {
    id<LRManifestErrorSink> _parentSink;
    id<LRManifestErrorSink> _uncleSink;
    NSString *_context;
}

+ (instancetype)childErrorSinkWithParentSink:(id<LRManifestErrorSink>)parentSink context:(NSString *)context uncleSink:(id<LRManifestErrorSink>)uncleSink {
    return [[self alloc] initWithParentSink:parentSink context:context uncleSink:uncleSink];
}

- (id)initWithParentSink:(id<LRManifestErrorSink>)parentSink context:(NSString *)context uncleSink:(id<LRManifestErrorSink>)uncleSink {
    self = [super init];
    if (self) {
        _parentSink = parentSink;
        _uncleSink = uncleSink;
        _context = [context copy];
    }
    return self;
}

- (void)addErrorMessage:(NSString *)message {
    if (_context) {
        message = [NSString stringWithFormat:@"%@ in %@", message, _context];
    }

    if (_parentSink) {
        [_parentSink addErrorMessage:message];
    }

    if (_uncleSink) {
        [_uncleSink addErrorMessage:message];
    }
}

@end
