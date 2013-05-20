
#import "HomebrewContainer.h"
#import "RuntimeGlobals.h"
#import "HomebrewRubyInstance.h"
#import "ATSandboxing.h"

NSString *GetDefaultHomebrewPath() {
    return [ATRealHomeDirectory() stringByAppendingPathComponent:@"/usr/local/Cellar/ruby"];
}


@interface HomebrewContainer ()

@property(nonatomic, strong) NSURL *rootUrl;

@end



@implementation HomebrewContainer

+ (NSString *)containerTypeIdentifier {
    return @"homebrew";
}

- (id)initWithURL:(NSURL *)url {
    return [self initWithMemento:nil additionalInfo:@{@"url": url}];
}

- (id)initWithMemento:(NSDictionary *)memento additionalInfo:(NSDictionary *)additionalInfo {
    self = [super initWithMemento:memento additionalInfo:additionalInfo];
    if (self) {
        self.rootUrl = ATInitOrResolveSecurityScopedURL(self.memento, additionalInfo[@"url"], ATSecurityScopedURLOptionsReadWrite);
        [self.rootUrl startAccessingSecurityScopedResource];
    }
    return self;
}

- (NSString *)rootPath {
    return [self.rootUrl path];
}

- (NSString *)rubiesPath {
    return [self.rootPath stringByAppendingPathComponent:@"rubies"];
}

- (NSString *)binPath {
    return [self.rootPath stringByAppendingPathComponent:@"bin"];
}

- (NSString *)title {
    return [self.rootPath stringByAbbreviatingTildeInPathUsingRealHomeDirectory];
}

- (void)doValidate {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        NSError *error;
        BOOL isDir;

        if (![[NSFileManager defaultManager] fileExistsAtPath:self.rootPath isDirectory:&isDir] || !isDir) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self setInvalidWithError:[NSError errorWithDomain:LRRuntimeManagerErrorDomain code:LRRuntimeManagerErrorValidationFailed userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"RVM directory not found at %@", self.rootPath]}]];
            });
            return;
        }

        NSString *versionFile = [self.rootPath stringByAppendingPathComponent:@"VERSION"];
        if (![[NSFileManager defaultManager] fileExistsAtPath:versionFile]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self setInvalidWithError:[NSError errorWithDomain:LRRuntimeManagerErrorDomain code:LRRuntimeManagerErrorValidationFailed userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"RVM VERSION file not found at %@", versionFile]}]];
            });
            return;
        }
        if (![[NSFileManager defaultManager] fileExistsAtPath:self.rubiesPath isDirectory:&isDir] || !isDir) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self setInvalidWithError:[NSError errorWithDomain:LRRuntimeManagerErrorDomain code:LRRuntimeManagerErrorValidationFailed userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"RVM rubies subfolder not found at %@", self.rubiesPath]}]];
            });
            return;
        }

        NSString *version = [NSString stringWithContentsOfFile:versionFile encoding:NSUTF8StringEncoding error:&error];
        if (!version) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self setInvalidWithError:[NSError errorWithDomain:LRRuntimeManagerErrorDomain code:LRRuntimeManagerErrorValidationFailed userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"RVM directory not accessible (sandboxing issue?), cannot read %@", versionFile]}]];
            });
            return;
        }
        self.version = [version stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

        NSArray *rubySubfolders = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:self.rubiesPath error:&error];
        NSMutableArray *rubyInstancesData = [NSMutableArray array];
        for (NSString *subfolder in rubySubfolders) {
            if ([subfolder isEqualToString:@"default"])
                continue;

            NSString *rubyPath = [self.rubiesPath stringByAppendingPathComponent:subfolder];
            if ([[NSFileManager defaultManager] fileExistsAtPath:rubyPath isDirectory:&isDir] && isDir) {
                [rubyInstancesData addObject:@{@"name": subfolder, @"identifier": [NSString stringWithFormat:@"homebrew:%@", subfolder]}];
            }
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            [self updateInstancesWithData:rubyInstancesData];
            [self setValid];
        });
    });
}

- (RuntimeInstance *)newRuntimeInstanceWithData:(NSDictionary *)data {
    return [[HomebrewRubyInstance alloc] initWithIdentifier:data[@"identifier"] name:data[@"name"] container:self];
}

- (NSString *)validationResultSummary {
    return [NSString stringWithFormat:@"Homebrew %@, %d %@", self.version, (int)self.instances.count, (self.instances.count == 1 ? @"ruby" : @"rubies")];
}


#pragma mark - Presentation

- (NSString *)imageName {
    return @"HomebrewContainer";
}

- (NSString *)mainLabel {
    return [NSString stringWithFormat:@"Homebrew"];
}

- (NSString *)detailLabel {
    return [self.rootPath stringByAbbreviatingTildeInPathUsingRealHomeDirectory];
}

@end
