
#import "LRSelfTest.h"
#import "Workspace.h"
#import "Project.h"
#import "OldFSTree.h"
#import "LiveReload-Swift-x.h"
#import "LROperationResult.h"
#import "LRSelfTestOutputFile.h"
#import "LRSelfTestBrowserRequestExpectation.h"
#import "LRSelfTestMessageExpectation.h"
#import "LRSelfTestHelpers.h"

#import "ATObservation.h"
#import "ATFunctionalStyle.h"


#define return_error(returnValue, outError, error)  do { \
        if (outError) *outError = error; \
        return returnValue; \
    } while(0)


@interface LRSelfTest ()

@property(nonatomic, readonly) NSURL *folderURL;
@property(nonatomic, readonly) NSURL *manifestURL;
@property(nonatomic, readonly) NSDictionary *manifest;
@property(nonatomic, readonly) NSDictionary *projectMemento;

@property(nonatomic, readonly) Project *project;

@end


@implementation LRSelfTest {
    LRTestOptions _options;

    BOOL _skip;
    BOOL _legacy;

    NSMutableArray *_outputFiles;
    NSSet *_originalFiles;
    NSSet *_sourceFiles;

    NSMutableArray *_browserRequestExpectations;
    BOOL _browserRequestExpectationsSpecified;

    NSMutableArray *_changedFiles;
    BOOL _changedFilesSpecified;

    NSMutableArray *_messageExpectations;

    BOOL _analysisRunning;
    BOOL _buildRunning;
}

- (id)initWithFolderURL:(NSURL *)folderURL options:(LRTestOptions)options {
    self = [super init];
    if (self) {
        _folderURL = [folderURL copy];
        _options = options;

        _manifestURL = [_folderURL URLByAppendingPathComponent:@"livereload-test.json"];
        _outputFiles = [NSMutableArray new];
        _browserRequestExpectations = [NSMutableArray new];
        _valid = YES;
        _legacy = !!(_options & LRTestOptionLegacy);
        _messageExpectations = [NSMutableArray new];

        [self observeNotification:ProjectAnalysisDidFinishNotification withSelector:@selector(_checkAnalysisStatus)];
        [self observeNotification:ProjectBuildFinishedNotification withSelector:@selector(_checkBuildStatus)];

        [self analyze];
    }
    return self;
}

- (void)analyze {
    NSData *data = [NSData dataWithContentsOfURL:_manifestURL options:0 error:NULL];
    if (!data) {
        _error = [NSError errorWithDomain:@"com.livereload.tests" code:1 userInfo:@{NSLocalizedDescriptionKey:@"Test manifest cannot be loaded"}];
        _valid = NO;
        return;
    }
    _manifest = [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL];
    if (!_manifest) {
        _error = [NSError errorWithDomain:@"com.livereload.tests" code:1 userInfo:@{NSLocalizedDescriptionKey:@"Test manifest is invalid"}];
        _valid = NO;
        return;
    }

    NSString *settingsKey = (_legacy ? @"2x-settings" : @"settings");
    _projectMemento = _manifest[settingsKey] ?: @{};
    if (_legacy && nil == _manifest[settingsKey])
        _skip = YES;

    NSDictionary *outputs = _manifest[@"outputs"] ?: @{};
    [outputs enumerateKeysAndObjectsUsingBlock:^(NSString *relativePath, id expectation, BOOL *stop) {
        NSURL *absoluteURL = [_folderURL URLByAppendingPathComponent:relativePath];
        [_outputFiles addObject:[[LRSelfTestOutputFile alloc] initWithRelativePath:relativePath absoluteURL:absoluteURL expectation:expectation]];
    }];

    NSArray *browserRequestExpectations = _manifest[@"browserRequests"];
    if (browserRequestExpectations) {
        _browserRequestExpectationsSpecified = YES;
        [_browserRequestExpectations addObjectsFromArray:[browserRequestExpectations arrayByMappingElementsUsingBlock:^id(id expectationData) {
            return [[LRSelfTestBrowserRequestExpectation alloc] initWithExpectationData:expectationData];
        }]];
    }

    NSArray *changes = _manifest[@"changes"];
    if (changes) {
        _changedFilesSpecified = YES;
        _changedFiles = [changes copy];
    }

    NSDictionary *sources = _manifest[@"sources"] ?: @{};
    _sourceFiles = [NSSet setWithArray:[[sources allKeys] arrayByAddingObjectsFromArray:@[@"livereload-test.json"]]];

    NSArray *errors = _manifest[@"errors"] ?: @[];
    [_messageExpectations addObjectsFromArray:[errors arrayByMappingElementsUsingBlock:^id(NSDictionary *messageData) {
        return [LRSelfTestMessageExpectation messageExpectationWithDictionary:messageData severity:LRMessageSeverityError];
    }]];
}

- (void)run {
    if (!_valid) {
        return [self _failWithError:_error];
    }
    if (_skip) {
        return [self _failWithError:[NSError errorWithDomain:@"com.livereload.tests" code:1 userInfo:@{NSLocalizedDescriptionKey:@"Legacy mode not supported"}]];
    }

    for (LRSelfTestOutputFile *outputFile in _outputFiles) {
        [outputFile removeOutputFile];
    }

    _analysisRunning = YES;

    _project = [[Project alloc] initWithURL:self.folderURL memento:_projectMemento];
    [[Workspace sharedWorkspace] addProjectsObject:_project];

    [self _checkAnalysisStatus];
}

- (void)_checkAnalysisStatus {
    if (_analysisRunning && !_project.analysisInProgress) {
        _analysisRunning = NO;
        [self _startBuild];
    }
}

- (void)_startBuild {
    _buildRunning = YES;
    if (_changedFilesSpecified) {
        [_project rebuildFilesAtRelativePaths:_changedFiles];
    } else {
        [_project rebuildAll];
    }
    [self _checkBuildStatus];
}

- (void)_checkBuildStatus {
    if (_buildRunning && !_project.buildInProgress) {
        [self _buildFinished];
    }
}

- (void)_buildFinished {
    NSError *__autoreleasing error;
    for (LRSelfTestOutputFile *outputFile in _outputFiles) {
        if (![outputFile verifyExpectationsWithError:&error]) {
            return [self _failWithError:error];
        }
    }

    LRBuild *build = _project.lastFinishedBuild;

    if (!LRSelfTestMatchUnorderedArrays(_messageExpectations, build.messages, @"Incorrect messages", &error, ^BOOL(LRSelfTestMessageExpectation *expectation, LRMessage *value) {
        return [expectation matchesMessage:value];
    })) {
        return [self _failWithError:error];
    }

    if (build.failed && _messageExpectations.count == 0) {
        LROperationResult *failure = build.firstFailure;
        LRMessage *firstError = [failure.errors firstObject];
        return [self _failWithError:([NSError errorWithDomain:@"com.livereload.tests" code:1 userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"Build failed, but the failure hasn't been caught by message checking: %@", firstError]}])];
    }

    if (![self _verifyBrowserRequestExpectationsWithBuild:build error:&error]) {
        return [self _failWithError:error];
    }

    // all expectations are met, so delete the expected files
    for (LRSelfTestOutputFile *outputFile in _outputFiles) {
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

- (BOOL)_verifyBrowserRequestExpectationsWithBuild:(LRBuild *)build error:(NSError **)error {
    if (!_browserRequestExpectationsSpecified)
        return YES;

    if (!build) {
        return_error(NO, error, ([NSError errorWithDomain:@"com.livereload.tests" code:1 userInfo:@{NSLocalizedDescriptionKey: @"No finished build in LRProject."}]));
    }

    NSArray *requests = build.reloadRequests;
    NSArray *expectations = _browserRequestExpectations;
    NSUInteger minCount = MIN(requests.count, expectations.count);
    for (NSUInteger i = 0; i < minCount; ++i) {
        NSDictionary *request = requests[i];
        LRSelfTestBrowserRequestExpectation *expectation = expectations[i];
        if (![expectation matchesRequest:request]) {
            return_error(NO, error, ([NSError errorWithDomain:@"com.livereload.tests" code:1 userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"Request R does not match expectation E; R = %@, E = %@, RR = %@, EE = %@", request, expectation, requests, expectations]}]));
        }
    }

    if (minCount < expectations.count) {
        NSArray *unmatched = [expectations subarrayWithRange:NSMakeRange(expectations.count - minCount, minCount)];
        return_error(NO, error, ([NSError errorWithDomain:@"com.livereload.tests" code:1 userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"Not enough requests! Unmatched expectations = %@, RR = %@, EE = %@", unmatched, requests, expectations]}]));
    } else if (minCount < requests.count) {
        NSArray *unmatched = [requests subarrayWithRange:NSMakeRange(requests.count - minCount, minCount)];
        return_error(NO, error, ([NSError errorWithDomain:@"com.livereload.tests" code:1 userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"Too many requests! Extra requests = %@, RR = %@, EE = %@", unmatched, requests, expectations]}]));
    }

    return YES;
}

- (void)_succeeded {
    _buildRunning = NO;
    _error = nil;
    if (_completionBlock) {
        _completionBlock();
        _completionBlock = nil;
    }
}

- (void)_failWithError:(NSError *)error {
    _buildRunning = NO;
    _error = error;
    if (_completionBlock) {
        _completionBlock();
        _completionBlock = nil;
    }
}

@end
