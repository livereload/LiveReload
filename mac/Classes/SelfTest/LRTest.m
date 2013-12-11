
#import "LRTest.h"


@interface LRTest ()

@property(nonatomic, readonly) NSURL *folderURL;
@property(nonatomic, readonly) NSURL *manifestURL;
@property(nonatomic, readonly) NSDictionary *manifest;

@end


@implementation LRTest

- (id)initWithFolderURL:(NSURL *)folderURL {
    self = [super init];
    if (self) {
        _folderURL = [folderURL copy];
        _manifestURL = [_folderURL URLByAppendingPathComponent:@"livereload-test.json"];
        [self analyze];
    }
    return self;
}

- (void)analyze {
    NSData *data = [NSData dataWithContentsOfURL:_manifestURL options:0 error:NULL];
    if (!data) {
        _error = [NSError errorWithDomain:@"com.livereload.tests" code:1 userInfo:@{}];
        _valid = NO;
        return;
    }
    _manifest = [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL];
    if (!_manifest) {
        _error = [NSError errorWithDomain:@"com.livereload.tests" code:1 userInfo:@{}];
        _valid = NO;
        return;
    }
}

- (void)run {
    [self _succeeded];
}

- (void)_succeeded {
    _error = nil;
    if (_completionBlock) {
        _completionBlock();
        _completionBlock = nil;
    }
}

- (void)_failWithError:(NSError *)error {
    _error = error;
    if (_completionBlock) {
        _completionBlock();
        _completionBlock = nil;
    }
}

@end
