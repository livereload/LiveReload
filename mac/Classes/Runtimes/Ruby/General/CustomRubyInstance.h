
#import "RubyInstance.h"

@interface CustomRubyInstance : RubyInstance

- (id)initWithURL:(NSURL *)url;

@property(nonatomic, strong, readonly) NSURL *rootUrl;

@end
