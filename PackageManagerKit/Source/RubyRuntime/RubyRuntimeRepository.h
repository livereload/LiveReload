
#import <Foundation/Foundation.h>
#import "RuntimeRepository.h"


@class RuntimeContainer;


@interface RubyRuntimeRepository : RuntimeRepository

- (RuntimeInstance *)addCustomRubyAtURL:(NSURL *)url;

@end
