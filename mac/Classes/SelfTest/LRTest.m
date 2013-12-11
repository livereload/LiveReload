
#import "LRTest.h"
#import "Workspace.h"
#import "Project.h"

#import "ATObservation.h"


@interface LRTest ()

@property(nonatomic, readonly) NSURL *folderURL;
@property(nonatomic, readonly) NSURL *manifestURL;
@property(nonatomic, readonly) NSDictionary *manifest;

@property(nonatomic, readonly) Project *project;
@property(nonatomic, readonly, getter=isRunning) BOOL running;

@end


@implementation LRTest

- (id)initWithFolderURL:(NSURL *)folderURL {
    self = [super init];
    if (self) {
        _folderURL = [folderURL copy];
        _manifestURL = [_folderURL URLByAppendingPathComponent:@"livereload-test.json"];

        [self observeNotification:ProjectBuildFinishedNotification withSelector:@selector(_checkBuildStatus)];

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
    _project = [[Project alloc] initWithURL:self.folderURL memento:@{@"actions": @[@{@"action": @"haml", @"enabled": @1, @"version": @"*-stable", @"filter": @"subdir:.", @"output": @"subdir:."}]}];
    [[Workspace sharedWorkspace] addProjectsObject:_project];

    _running = YES;
    [_project rebuildAll];
    [self _checkBuildStatus];
}

- (void)_checkBuildStatus {
    if (_running && !_project.buildInProgress) {
        [self _succeeded];
    }
}

- (void)_succeeded {
    _running = NO;
    _error = nil;
    if (_completionBlock) {
        _completionBlock();
        _completionBlock = nil;
    }
}

- (void)_failWithError:(NSError *)error {
    _running = NO;
    _error = error;
    if (_completionBlock) {
        _completionBlock();
        _completionBlock = nil;
    }
}

@end
