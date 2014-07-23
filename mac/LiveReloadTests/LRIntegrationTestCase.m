
#import "LRIntegrationTestCase.h"
#import "ATAsyncTestCase.h"


@interface LRIntegrationTestCase ()

@end


@implementation LRIntegrationTestCase {
    NSURL *_baseFolderURL;
    LRSelfTest *_currentTest;
}

- (void)setUp {
    [super setUp];

    NSString *path = [NSProcessInfo processInfo].environment[@"LRRunTests"];
    NSAssert(!!path, @"LRRunTests must be set.");

    _baseFolderURL = [NSURL fileURLWithPath:path];

    NSLog(@"Waiting for initialization to finish...");
    [self waitForCondition:^BOOL{
        NSArray *packageContainers = [[PluginManager sharedPluginManager].plugins valueForKeyPath:@"@unionOfArrays.bundledPackageContainers"];
        return (packageContainers.count > 0) && [packageContainers all:^BOOL(LRPackageContainer *container) {
            return !container.updateInProgress;
        }];
    } withTimeout:3000];
    NSLog(@"Initialization finished.");
}

- (NSError *)runProjectTestNamed:(NSString *)name options:(LRTestOptions)options {
    LRSelfTest *test = _currentTest = [[LRSelfTest alloc] initWithFolderURL:[_baseFolderURL URLByAppendingPathComponent:name] options:options];
    test.completionBlock = self.completionBlock;
    [test run];
    [self waitWithTimeout:3.0];
    _currentTest = nil;
    return test.error;
}

@end
