
#import <Foundation/Foundation.h>
#import "RuntimeRepository.h"


@class RuntimeContainer;


@interface RubyRuntimeRepository : RuntimeRepository

+ (RubyRuntimeRepository *)sharedRubyManager;

- (RuntimeInstance *)addCustomRubyAtURL:(NSURL *)url;

@end
