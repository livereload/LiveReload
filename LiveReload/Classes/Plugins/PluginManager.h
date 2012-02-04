
#import <Foundation/Foundation.h>


@class Compiler;

@interface PluginManager : NSObject {
@private
    NSArray *_plugins;
    NSMutableSet *_loadedPluginNames;
    NSArray *_userPluginNames;
}

+ (PluginManager *)sharedPluginManager;

- (void)reloadPlugins;

@property(nonatomic, readonly) NSArray *plugins;
@property(nonatomic, readonly) NSArray *compilers;
@property(nonatomic, readonly) NSArray *compilerSourceExtensions;
@property(nonatomic, readonly) NSArray *userPluginNames;

- (Compiler *)compilerForExtension:(NSString *)extension;
- (Compiler *)compilerWithUniqueId:(NSString *)uniqueId;

@end
