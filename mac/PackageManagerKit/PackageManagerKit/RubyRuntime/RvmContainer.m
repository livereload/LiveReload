
#import "RvmContainer.h"
#import "RuntimeGlobals.h"
#import "RvmRubyInstance.h"
@import LRCommons;



NSString *GetDefaultRvmPath() {
    return [ATRealHomeDirectory() stringByAppendingPathComponent:@".rvm"];
}


@interface RvmContainer ()

@property(nonatomic, strong) NSURL *rootUrl;

@end



@implementation RvmContainer

+ (NSString *)containerTypeIdentifier {
    return @"rvm";
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

- (NSURL *)environmentsURL {
    return [self.rootUrl URLByAppendingPathComponent:@"environments"];
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
                [rubyInstancesData addObject:@{@"name": subfolder, @"identifier": [NSString stringWithFormat:@"rvm:%@", subfolder]}];
            }
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            [self updateInstancesWithData:rubyInstancesData];
            [self setValid];
        });
    });
}

- (RuntimeInstance *)newRuntimeInstanceWithData:(NSDictionary *)data {
    return [[RvmRubyInstance alloc] initWithIdentifier:data[@"identifier"] name:data[@"name"] container:self];
}

- (NSString *)validationResultSummary {
    return [NSString stringWithFormat:@"RVM %@, %d %@", self.version, (int)self.instances.count, (self.instances.count == 1 ? @"ruby" : @"rubies")];
}


#pragma mark - Presentation

- (NSString *)imageName {
    return @"RvmContainer";
}

- (NSString *)mainLabel {
    return [NSString stringWithFormat:@"RVM"];
}

- (NSString *)detailLabel {
    return [self.rootPath stringByAbbreviatingTildeInPathUsingRealHomeDirectory];
}

@end
