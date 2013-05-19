
#import <Foundation/Foundation.h>
#import "RuntimeManager.h"


@class RuntimeContainer;


@interface RubyManager : RuntimeManager

+ (RubyManager *)sharedRubyManager;

- (RuntimeInstance *)addCustomRubyAtURL:(NSURL *)url;

@end
