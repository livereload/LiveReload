
#import "PluginManager.h"
#import "Plugin.h"
#import "Compiler.h"


static PluginManager *sharedPluginManager;


@implementation PluginManager

+ (PluginManager *)sharedPluginManager {
    if (sharedPluginManager == nil) {
        sharedPluginManager = [[PluginManager alloc] init];
    }
    return sharedPluginManager;
}

- (id)init {
    self = [super init];
    if (self) {
    }

    return self;
}

- (void)dealloc {
    [super dealloc];
}

- (void)reloadPlugins {
    NSArray *paths = [[NSBundle mainBundle] pathsForResourcesOfType:@"lrplugin" inDirectory:@""];
    NSLog(@"Plugins found: %@", [paths description]);
    NSMutableArray *plugins = [NSMutableArray array];
    for (NSString *path in paths) {
        [plugins addObject:[[[Plugin alloc] initWithPath:path] autorelease]];
    }
    [_plugins release], _plugins = [plugins copy];
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
