
#import "LRIntegrationTestCase.h"
#import "ATAsyncTestCase.h"


@interface LRIntegrationTestCase ()

@end


@implementation LRIntegrationTestCase {
    NSURL *_baseFolderURL;
}

- (void)setUp {
    [super setUp];

    _baseFolderURL = [NSURL fileURLWithPath:[@"~/dev/livereload/devel/mac/LiveReloadTestProjects" stringByExpandingTildeInPath]];

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
    LRSelfTest *test = [[LRSelfTest alloc] initWithFolderURL:[_baseFolderURL URLByAppendingPathComponent:name] options:options];
    test.completionBlock = self.completionBlock;
    [test run];
    [self waitWithTimeout:3.0];
    return test.error;
}

@end
