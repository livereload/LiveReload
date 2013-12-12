
#import "LRTest.h"
#import "Workspace.h"
#import "Project.h"
#import "OldFSTree.h"
#import "LRTestOutputFile.h"

#import "ATObservation.h"


@interface LRTest ()

@property(nonatomic, readonly) NSURL *folderURL;
@property(nonatomic, readonly) NSURL *manifestURL;
@property(nonatomic, readonly) NSDictionary *manifest;
@property(nonatomic, readonly) NSDictionary *projectMemento;

@property(nonatomic, readonly) Project *project;
@property(nonatomic, readonly, getter=isRunning) BOOL running;

@end


@implementation LRTest {
    NSMutableArray *_outputFiles;
    NSSet *_originalFiles;
    NSSet *_sourceFiles;
}

- (id)initWithFolderURL:(NSURL *)folderURL {
    self = [super init];
    if (self) {
        _folderURL = [folderURL copy];
        _manifestURL = [_folderURL URLByAppendingPathComponent:@"livereload-test.json"];
        _outputFiles = [NSMutableArray new];

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

    _projectMemento = _manifest[@"settings"] ?: @{};

    NSDictionary *outputs = _manifest[@"outputs"] ?: @{};
    [outputs enumerateKeysAndObjectsUsingBlock:^(NSString *relativePath, id expectation, BOOL *stop) {
        NSURL *absoluteURL = [_folderURL URLByAppendingPathComponent:relativePath];
        [_outputFiles addObject:[[LRTestOutputFile alloc] initWithRelativePath:relativePath absoluteURL:absoluteURL expectation:expectation]];
    }];

    NSDictionary *sources = _manifest[@"sources"] ?: @{};
    _sourceFiles = [NSSet setWithArray:[[sources allKeys] arrayByAddingObjectsFromArray:@[@"livereload-test.json"]]];
}

- (void)run {
    for (LRTestOutputFile *outputFile in _outputFiles) {
        [outputFile removeOutputFile];
    }

    _project = [[Project alloc] initWithURL:self.folderURL memento:_projectMemento];
    [[Workspace sharedWorkspace] addProjectsObject:_project];

    _running = YES;
    [_project rebuildAll];
    [self _checkBuildStatus];
}

- (void)_checkBuildStatus {
    if (_running && !_project.buildInProgress) {
        [self _buildFinished];
    }
}

- (void)_buildFinished {
    for (LRTestOutputFile *outputFile in _outputFiles) {
        NSError *__autoreleasing error;
        if (![outputFile verifyExpectationsWithError:&error]) {
            return [self _failWithError:error];
        }
    }

    // all expectations are met, so delete the expected files
    for (LRTestOutputFile *outputFile in _outputFiles) {
        [outputFile removeOutputFile];
    }

    [_project rescanTree];
    NSMutableSet *newFiles = [NSMutableSet setWithArray:_project.tree.filePaths];
    [newFiles minusSet:_sourceFiles];
    [newFiles minusSet:[NSSet setWithArray:[_outputFiles valueForKeyPath:@"relativePath"]]];

    if (newFiles.count > 0) {
        // any extra files are left in the test folder for inspection
        return [self _failWithError:[NSError errorWithDomain:@"com.livereload.tests" code:1 userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"Extra output files created: %@", [[newFiles allObjects] componentsJoinedByString:@", "]]}]];
    }

    [self _succeeded];
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
