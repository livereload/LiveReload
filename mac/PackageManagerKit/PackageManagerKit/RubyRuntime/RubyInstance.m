
#import "RubyInstance.h"

#import "LRPackageManager.h"
#import "LRPackageType.h"
#import "LRPackageContainer.h"

#import "RuntimeGlobals.h"
@import LRCommons;


@implementation RubyInstance

- (void)doValidate {
    if (![[NSFileManager defaultManager] fileExistsAtPath:[self executablePath]]) {
        [self validationFailedWithError:[NSError errorWithDomain:LRRuntimeManagerErrorDomain code:LRRuntimeManagerErrorValidationFailed userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"Ruby executable file (bin/ruby) not found at %@", self.executablePath]}]];
        return;
    }

    ATLaunchUnixTaskAndCaptureOutput(self.executableURL, @[@"--version"], ATLaunchUnixTaskAndCaptureOutputOptionsIgnoreSandbox|ATLaunchUnixTaskAndCaptureOutputOptionsMergeStdoutAndStderr, nil, ^(NSString *outputText, NSString *stderrText, NSError *error) {
        NSArray *components = [[outputText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];

        if (error) {
            [self validationFailedWithError:error];
            return;
        }
        if ([[components objectAtIndex:0] isEqualToString:@"ruby"] && components.count > 1) {
            NSString *version = [components objectAtIndex:1];

            ATLaunchUnixTaskAndCaptureOutput(self.gemExecutableURL, @[@"environment", @"gempath"], ATLaunchUnixTaskAndCaptureOutputOptionsIgnoreSandbox, nil, ^(NSString *outputText, NSString *stderrText, NSError *error) {

                NSMutableArray *defaultPackageContainers = [NSMutableArray new];
                if (error) {
                    NSLog(@"Gem validation failed: %@ - %ld - %@", error.domain, (long)error.code, error.localizedDescription);
                } else {
                    NSArray *pathComponents = [[[outputText componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]] objectAtIndex:0] componentsSeparatedByString:@":"];
                    for (NSString *pathComponent in pathComponents) {
                        NSString *trimmed = [pathComponent stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                        NSURL *folderURL = [NSURL fileURLWithPath:trimmed];
                        if ([folderURL checkResourceIsReachableAndReturnError:NULL]) {
                            // TODO XXX FIXME
#if 0
                            LRPackageContainer *container = [[[AppState sharedAppState].packageManager packageTypeNamed:@"gem"] packageContainerAtFolderURL:folderURL];
                            container.containerType = LRPackageContainerTypeRuntimeInstance;
                            container.runtimeInstance = self;
                            [defaultPackageContainers addObject:container];
#endif
                        }
                    }
                }

                [self validationSucceededWithData:@{@"version": version, @"defaultPackageContainers": defaultPackageContainers}];
            });
        } else {
            [self validationFailedWithError:[NSError errorWithDomain:LRRuntimeManagerErrorDomain code:LRRuntimeManagerErrorValidationFailed userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"Failed to parse output of --version: '%@'", outputText]}]];
        }
    });
}


#pragma mark - Presentation

- (NSString *)imageName {
    return @"RubyRuntime";
}


#pragma mark - Gems

- (NSURL *)gemExecutableURL {
    NSURL *dir = [self.executableURL URLByDeletingLastPathComponent];
    NSString *fileName = [self.executableURL lastPathComponent];
    return [dir URLByAppendingPathComponent:[fileName stringByReplacingOccurrencesOfString:@"ruby" withString:@"gem"]];
}

- (NSArray *)launchArgumentsWithAdditionalRuntimeContainers:(NSArray *)additionalRuntimeContainers environment:(NSMutableDictionary *)environment {
    NSString *gemPath = [[[additionalRuntimeContainers arrayByAddingObjectsFromArray:self.defaultPackageContainers] valueForKeyPath:@"folderURL.path"] componentsJoinedByString:@":"];
    environment[@"GEM_PATH"] = gemPath;

    return @[self.executableURL.path];
}

@end
