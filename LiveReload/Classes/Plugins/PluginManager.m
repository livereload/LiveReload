
#import "PluginManager.h"
#import "Plugin.h"
#import "Compiler.h"


static PluginManager *sharedPluginManager;


@implementation PluginManager

@synthesize userPluginNames=_userPluginNames;

+ (PluginManager *)sharedPluginManager {
    if (sharedPluginManager == nil) {
        sharedPluginManager = [[PluginManager alloc] init];
    }
    return sharedPluginManager;
}

- (id)init {
    self = [super init];
    if (self) {
        _loadedPluginNames = [[NSMutableSet alloc] init];
    }

    return self;
}

- (void)dealloc {
    [super dealloc];
}

- (void)loadPluginFromFolder:(NSString *)pluginFolder into:(NSMutableArray *)plugins {
    NSString *name = [[pluginFolder lastPathComponent] stringByDeletingPathExtension];

    if ([_loadedPluginNames containsObject:name])
        return;
    [_loadedPluginNames addObject:name];

    [plugins addObject:[[[Plugin alloc] initWithPath:pluginFolder] autorelease]];
}

- (void)loadPluginsFromFolder:(NSString *)pluginsFolder into:(NSMutableArray *)plugins {
    for (NSString *fileName in [[[NSFileManager defaultManager] contentsOfDirectoryAtPath:pluginsFolder error:nil] sortedArrayUsingSelector:@selector(compare:)]) {
        if ([[fileName pathExtension] isEqualToString:@"lrplugin"]) {
            [self loadPluginFromFolder:[pluginsFolder stringByAppendingPathComponent:fileName] into:plugins];
        }
    }
}

- (void)reloadPlugins {
    NSMutableArray *plugins = [NSMutableArray array];

    NSArray *libraryFolderPaths = [NSArray arrayWithObjects:@"~/Library/LiveReload", @"~/Dropbox/Library/LiveReload", nil];
    for (NSString *libraryFolderPath in libraryFolderPaths) {
        NSString *pluginsFolder = [[libraryFolderPath stringByAppendingPathComponent:@"Plugins"] stringByExpandingTildeInPath];
        [self loadPluginsFromFolder:pluginsFolder into:plugins];
    }

    [_userPluginNames release], _userPluginNames = [[NSArray alloc] initWithArray:[_loadedPluginNames allObjects]];

    NSString *bundledPluginsFolder;
    const char *pluginsOverrideFolder = getenv("LRBundledPluginsOverride");
    if (pluginsOverrideFolder && *pluginsOverrideFolder) {
        bundledPluginsFolder = [[NSString stringWithUTF8String:pluginsOverrideFolder] stringByExpandingTildeInPath];
    } else {
        bundledPluginsFolder = [[NSBundle mainBundle] resourcePath];
    }

    [self loadPluginsFromFolder:bundledPluginsFolder into:plugins];
    [_plugins release], _plugins = [plugins copy];

    NSLog(@"Plugins loaded:\n%@", [[_plugins valueForKeyPath:@"path"] componentsJoinedByString:@"\n"]);
}

- (NSArray *)plugins {
    NSAssert(_plugins != nil, @"Plugins not loaded yet");
    return _plugins;
}

- (NSArray *)compilers {
    return [self valueForKeyPath:@"plugins.@unionOfArrays.compilers"];
}

- (NSArray *)compilerSourceExtensions {
    return [self valueForKeyPath:@"compilers.@unionOfArrays.extensions"];
}

- (Compiler *)compilerForExtension:(NSString *)extension {
    for (Compiler *compiler in self.compilers) {
        if ([compiler.extensions containsObject:extension]) {
            return compiler;
        }
    }
    return nil;
}

- (Compiler *)compilerWithUniqueId:(NSString *)uniqueId {
    for (Compiler *compiler in self.compilers) {
        if ([compiler.uniqueId isEqualToString:uniqueId]) {
            return compiler;
        }
    }
    return nil;
}

@end
