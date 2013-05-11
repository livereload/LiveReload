
#import <Foundation/Foundation.h>
#import "Runtimes.h"
#import "RuntimeContainer.h"


NSString *RubyVersionAtPath(NSString *executablePath);
NSString *GetDefaultRvmPath();


@interface OldRubyManager : RuntimeManager

+ (OldRubyManager *)sharedRubyManager;

- (RuntimeInstance *)addCustomRubyAtURL:(NSURL *)url;

@property(nonatomic, readonly, strong) NSArray *instances;

@end


@interface OldRubyInstance : RuntimeInstance

- (void)resolveBookmark;

@end


@interface RvmContainer : RuntimeContainer

@end
