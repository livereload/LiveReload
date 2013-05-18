
#import "RubyInstance.h"


@class RvmContainer;


@interface RvmRubyInstance : RubyInstance

- (id)initWithIdentifier:(NSString *)identifier container:(RvmContainer *)container;

@end
