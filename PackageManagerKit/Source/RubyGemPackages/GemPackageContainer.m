
#import "GemPackageContainer.h"
#import "GemPackage.h"
#import "LRPackageType.h"
#import "GemVersion.h"

@import ExpressiveCocoa;


@interface GemPackageContainer ()

@end


@implementation GemPackageContainer

- (instancetype)initWithPackageType:(LRPackageType *)packageType folderURL:(NSURL *)folderURL {
    self = [super initWithPackageType:packageType];
    if (self) {
        _folderURL = [folderURL copy];
    }
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"GemPackageContainer(%@)", _folderURL.path];
}

- (void)doUpdate {
    static NSRegularExpression *linePattern;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        linePattern = [NSRegularExpression regularExpressionWithPattern:@"^(\\S+)\\s+\\((.*)\\)$" options:NSRegularExpressionAnchorsMatchLines error:NULL];
    });

    NSURL *url = [NSURL fileURLWithPath:@"/usr/bin/gem"];

    ATLaunchUnixTaskAndCaptureOutput(url, @[@"list", @"--all", @"--local"], ATLaunchUnixTaskAndCaptureOutputOptionsIgnoreSandbox|ATLaunchUnixTaskAndCaptureOutputOptionsMergeStdoutAndStderr, @{ATEnvironmentVariablesKey: @{@"GEM_PATH": self.folderURL.path, @"GEM_HOME": self.folderURL.path}}, ^(NSString *outputText, NSString *stderrText, NSError *error) {
        NSLog(@"Gem result:\n%@", outputText);

        NSMutableArray *packages = [NSMutableArray new];

        NSURL *gemFolderURL = [self.folderURL URLByAppendingPathComponent:@"gems"];

        [linePattern enumerateMatchesInString:outputText options:0 range:NSMakeRange(0, outputText.length) usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
            NSString *nameString = [outputText substringWithRange:[result rangeAtIndex:1]];
            NSArray *versionList = [[outputText substringWithRange:[result rangeAtIndex:2]] componentsSeparatedByString:@", "];
            for (NSString *versionString in versionList) {
                GemVersion *version = [GemVersion gemVersionWithString:versionString];

                NSString *packageFolderName = [NSString stringWithFormat:@"%@-%@", nameString, version.canonicalString];
                NSURL *packageFolderURL = [gemFolderURL URLByAppendingPathComponent:packageFolderName];

                NSDictionary *values = [packageFolderURL resourceValuesForKeys:@[NSURLNameKey, NSURLIsDirectoryKey] error:NULL];
                if (![values[NSURLIsDirectoryKey] boolValue])
                    continue;

                GemPackage *package = [[GemPackage alloc] initWithName:nameString version:version container:self sourceFolderURL:packageFolderURL];
                [packages addObject:package];
            }
        }];

        [self updateSucceededWithPackages:packages];
    });
}

@end
