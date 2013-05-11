
#import "CustomRubyInstance.h"
#import "ATSandboxing.h"

@implementation CustomRubyInstance

- (id)initWithURL:(NSURL *)url {
    NSString *identifier = [NSString stringWithFormat:@"custom:%@", [[url path] stringByAbbreviatingTildeInPathUsingRealHomeDirectory]];

    self = [self initWithDictionary:@{@"identifier": identifier, @"executablePath": [url.path stringByAppendingPathComponent:@"bin/ruby"]}];
    if (self) {
        [url startAccessingSecurityScopedResource];
    }
    return self;
}

@end
