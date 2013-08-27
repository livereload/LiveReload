
#import "PluginManager.h"
#import "Plugin.h"
#import "Compiler.h"
#import "ActionType.h"
#import "ATFunctionalStyle.h"


static PluginManager *sharedPluginManager;


@implementation PluginManager {
    NSMutableDictionary *_actionTypesByIdentifier;
    NSMutableArray *_actionTypes;
}

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


- (void)loadPluginFromFolder:(NSString *)pluginFolder into:(NSMutableArray *)plugins {
    NSString *name = [[pluginFolder lastPathComponent] stringByDeletingPathExtension];

    if ([_loadedPluginNames containsObject:name])
        return;
    [_loadedPluginNames addObject:name];

    [plugins addObject:[[Plugin alloc] initWithPath:pluginFolder]];
}

- (void)loadPluginsFromFolder:(NSString *)pluginsFolder into:(NSMutableArray *)plugins {
    for (NSString *fileName in [[[NSFileManager defaultManager] contentsOfDirectoryAtPath:pluginsFolder error:nil] sortedArrayUsingSelector:@selector(compare:)]) {
        if ([[fileName pathExtension] isEqualToString:@"lrplugin"]) {
            [self loadPluginFromFolder:[pluginsFolder stringByAppendingPathComponent:fileName] into:plugins];
        }
    }
}

- (void)addActionType:(ActionType *)actionType {
    NSString *identifier = actionType.identifier;
    if (_actionTypesByIdentifier[identifier])
        return;

    if (actionType.valid) {
        [_actionTypes addObject:actionType];
        _actionTypesByIdentifier[identifier] = actionType;
    } else {
        NSLog(@"Skipped invalid action type def: %@", identifier);
    }
}

- (void)reloadPlugins {
    _actionTypes = [NSMutableArray new];
    _actionTypesByIdentifier = [NSMutableDictionary new];

    NSMutableArray *plugins = [NSMutableArray array];

    NSArray *libraryFolderPaths = [NSArray arrayWithObjects:@"~/Library/LiveReload", @"~/Dropbox/Library/LiveReload", nil];
    for (NSString *libraryFolderPath in libraryFolderPaths) {
        NSString *pluginsFolder = [[libraryFolderPath stringByAppendingPathComponent:@"Plugins"] stringByExpandingTildeInPath];
        [self loadPluginsFromFolder:pluginsFolder into:plugins];
    }

    _userPluginNames = [[NSArray alloc] initWithArray:[_loadedPluginNames allObjects]];

    NSString *bundledPluginsFolder;
    const char *pluginsOverrideFolder = getenv("LRBundledPluginsOverride");
    if (pluginsOverrideFolder && *pluginsOverrideFolder) {
        bundledPluginsFolder = [[NSString stringWithUTF8String:pluginsOverrideFolder] stringByExpandingTildeInPath];
    } else {
        bundledPluginsFolder = [[NSBundle mainBundle] resourcePath];
    }

    [self loadPluginsFromFolder:bundledPluginsFolder into:plugins];
    _plugins = [plugins copy];

    for (Plugin *plugin in _plugins) {
        for (ActionType *item in plugin.actionTypes) {
            [self addActionType:item];
        }
    }

    NSDictionary *pluginNamesByPath = [[(NSArray *)[_plugins valueForKeyPath:@"path"] dictionaryWithElementsGroupedIntoArraysByKeyPath:@"stringByDeletingLastPathComponent"] dictionaryByMappingValuesToKeyPath:@"lastPathComponent"];

    NSLog(@"Plugins loaded: %@", pluginNamesByPath);
    NSLog(@"Action types: %@", _actionTypes);

    NSArray *badPlugins = [_plugins filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"errors[SIZE] > 0"]];
    NSLog(@"Number of plugins with errors: %d", (int)badPlugins.count);
    for (Plugin *plugin in badPlugins) {
        NSLog(@"Error messages for %@:\n%@", plugin.path.lastPathComponent, plugin.errors);
    }
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

- (ActionType *)actionTypeWithIdentifier:(NSString *)identifier {
    return _actionTypesByIdentifier[identifier];
}

@end
