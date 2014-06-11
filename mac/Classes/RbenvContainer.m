
#import "RbenvContainer.h"
#import "RuntimeGlobals.h"
#import "RbenvRubyInstance.h"
#import "ATGlobals.h"

NSString *GetDefaultRbenvPath() {
    NSString *option1 = [ATRealHomeDirectory() stringByAppendingPathComponent:@".rbenv"];
    NSString *option2 = @"/usr/local/var/rbenv";
    NSFileManager *fm = [NSFileManager defaultManager];
    if (![fm fileExistsAtPath:option1] && [fm fileExistsAtPath:option2])
        return option2;
    else
        return option1;
}


@interface RbenvContainer ()

@property(nonatomic, strong) NSURL *rootUrl;

@end



@implementation RbenvContainer

+ (NSString *)containerTypeIdentifier {
    return @"rbenv";
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
    return [self.rootPath stringByAppendingPathComponent:@"versions"];
}

- (NSString *)shimsPath {
    return [self.rootPath stringByAppendingPathComponent:@"shims"];
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
                [self setInvalidWithError:[NSError errorWithDomain:LRRuntimeManagerErrorDomain code:LRRuntimeManagerErrorValidationFailed userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"rbenv directory not found at %@", self.rootPath]}]];
            });
            return;
        }

        if (![[NSFileManager defaultManager] fileExistsAtPath:self.rubiesPath isDirectory:&isDir] || !isDir) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self setInvalidWithError:[NSError errorWithDomain:LRRuntimeManagerErrorDomain code:LRRuntimeManagerErrorValidationFailed userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"rbenv versions subfolder not found at %@", self.rubiesPath]}]];
            });
            return;
        }

        if (![[NSFileManager defaultManager] fileExistsAtPath:self.shimsPath isDirectory:&isDir] || !isDir) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self setInvalidWithError:[NSError errorWithDomain:LRRuntimeManagerErrorDomain code:LRRuntimeManagerErrorValidationFailed userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"rbenv shims subfolder not found at %@", self.shimsPath]}]];
            });
            return;
        }

        NSArray *rubySubfolders = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:self.rubiesPath error:&error];
        if (!rubySubfolders) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self setInvalidWithError:[NSError errorWithDomain:LRRuntimeManagerErrorDomain code:LRRuntimeManagerErrorValidationFailed userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"rbenv directory not accessible (sandboxing issue?), cannot list %@", self.rubiesPath]}]];
            });
            return;
        }

        NSMutableArray *rubyInstancesData = [NSMutableArray array];
        for (NSString *subfolder in rubySubfolders) {
            if ([subfolder isEqualToString:@"default"])
                continue;

            NSString *rubyPath = [self.rubiesPath stringByAppendingPathComponent:subfolder];
            if ([[NSFileManager defaultManager] fileExistsAtPath:rubyPath isDirectory:&isDir] && isDir) {
                [rubyInstancesData addObject:@{@"name": subfolder, @"identifier": [NSString stringWithFormat:@"rbenv:%@", subfolder]}];
            }
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            [self updateInstancesWithData:rubyInstancesData];
            [self setValid];
        });
    });
}

- (RuntimeInstance *)newRuntimeInstanceWithData:(NSDictionary *)data {
    return [[RbenvRubyInstance alloc] initWithIdentifier:data[@"identifier"] name:data[@"name"] container:self];
}

- (NSString *)validationResultSummary {
    return [NSString stringWithFormat:@"rbenv %@, %d %@", self.version, (int)self.instances.count, (self.instances.count == 1 ? @"ruby" : @"rubies")];
}


#pragma mark - Presentation

- (NSString *)imageName {
    return @"RbenvContainer";
}

- (NSString *)mainLabel {
    return [NSString stringWithFormat:@"rbenv"];
}

- (NSString *)detailLabel {
    return [self.rootPath stringByAbbreviatingTildeInPathUsingRealHomeDirectory];
}

@end
