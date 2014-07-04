
#import "Plugin.h"
#import "Compiler.h"
#import "ActionType.h"
#import "AppState.h"
#import "LRPackageManager.h"
#import "LRPackageType.h"
#import "LRPackageContainer.h"

#import "ATJson.h"
#import "Errors.h"


@implementation Plugin {
    NSMutableArray *_errors;
}

@synthesize path=_path;
@synthesize compilers=_compilers;

- (id)initWithPath:(NSString *)path {
    self = [super init];
    if (self) {
        NSURL *folderURL = [NSURL fileURLWithPath:path];

        _path = [path copy];
        _errors = [NSMutableArray new];

        NSURL *plist = [NSURL fileURLWithPath:[path stringByAppendingPathComponent:@"manifest.json"]];
        NSError *error;
        _info = [NSDictionary LR_dictionaryWithContentsOfJSONFileURL:plist error:&error];
        if (!_info) {
            [self addErrorMessage:[NSString stringWithFormat:@"Invalid plugin manifest: %@", error.localizedDescription]];
            _info = [[NSDictionary alloc] init];
        }

        NSMutableArray *compilers = [NSMutableArray array];
        for (NSDictionary *compilerInfo in [_info objectForKey:@"LRCompilers"]) {
            [compilers addObject:[[Compiler alloc] initWithDictionary:compilerInfo plugin:self]];
        }
        _compilers = [compilers copy];

        NSMutableArray *actionTypes = [NSMutableArray array];
        for (NSDictionary *options in [_info objectForKey:@"actions"]) {
            [actionTypes addObject:[[ActionType alloc] initWithManifest:options plugin:self]];
        }
        _actionTypes = [actionTypes copy];

        // find bundled packages
        NSMutableArray *bundledPackageContainers = [NSMutableArray new];
        for (LRPackageType *packageType in [AppState sharedAppState].packageManager.packageTypes) {
            NSURL *bundledPackagesURL = [folderURL URLByAppendingPathComponent:packageType.bundledPackagesFolderName];
            NSDictionary *values = [bundledPackagesURL resourceValuesForKeys:@[NSURLIsDirectoryKey] error:NULL];
            if ([values[NSURLIsDirectoryKey] boolValue]) {
                LRPackageContainer *container = [packageType packageContainerAtFolderURL:bundledPackagesURL];
                container.containerType = LRPackageContainerTypeBundled;
                [bundledPackageContainers addObject:container];
                [packageType addPackageContainer:container];
            }
        }
        _bundledPackageContainers = [bundledPackageContainers copy];
    }

    return self;
}

- (NSURL *)folderURL {
    return [NSURL fileURLWithPath:_path];
}

- (void)addErrorMessage:(NSString *)message {
    [_errors addObject:[NSError errorWithDomain:LRErrorDomain code:LRErrorPluginApiViolation userInfo:@{NSLocalizedDescriptionKey: message}]];
}

@end
