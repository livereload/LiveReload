
#import <Foundation/Foundation.h>
#import "RuntimeManager.h"


@class RuntimeContainer;


@interface RubyManager : RuntimeManager

+ (RubyManager *)sharedRubyManager;

- (void)addCustomContainer:(RuntimeContainer *)container;
- (RuntimeInstance *)addCustomRubyAtURL:(NSURL *)url;

@property(nonatomic, readonly, strong) NSArray *instances;
@property(nonatomic, readonly, strong) NSArray *containers;

@end
