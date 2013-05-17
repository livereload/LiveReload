
#import <Foundation/Foundation.h>
#import "RuntimeManager.h"


@interface RubyManager : RuntimeManager

+ (RubyManager *)sharedRubyManager;

- (RuntimeInstance *)addCustomRubyAtURL:(NSURL *)url;

@property(nonatomic, readonly, strong) NSArray *instances;

@end
