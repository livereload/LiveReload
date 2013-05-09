
#import <Foundation/Foundation.h>
#import "Runtimes.h"


NSString *RubyVersionAtPath(NSString *executablePath);


@interface RubyManager : RuntimeManager

+ (RubyManager *)sharedRubyManager;

- (RuntimeInstance *)addCustomRubyAtURL:(NSURL *)url;

@property(nonatomic, readonly, strong) NSArray *instances;

@end


@interface RubyInstance : RuntimeInstance

@end
