
#import <Foundation/Foundation.h>
#import "Runtimes.h"


NSString *RubyVersionAtPath(NSString *executablePath);
NSString *GetDefaultRvmPath();


@interface RubyManager : RuntimeManager

+ (RubyManager *)sharedRubyManager;

- (RuntimeInstance *)addCustomRubyAtURL:(NSURL *)url;

- (RuntimeContainer *)addRvmContainerAtURL:(NSURL *)url;

@property(nonatomic, readonly, strong) NSArray *instances;

@end


@interface RubyInstance : RuntimeInstance

- (void)resolveBookmark;

@end


@interface RvmContainer : RuntimeContainer

@end