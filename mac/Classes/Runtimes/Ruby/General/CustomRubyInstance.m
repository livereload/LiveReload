
#import "CustomRubyInstance.h"
#import "ATSandboxing.h"


@interface CustomRubyInstance ()

@property(nonatomic, strong) NSURL *rootUrl;

@end


@implementation CustomRubyInstance

- (id)initWithURL:(NSURL *)url {
    NSString *identifier = [NSString stringWithFormat:@"custom:%@", [[url path] stringByAbbreviatingTildeInPathUsingRealHomeDirectory]];
    return [self initWithMemento:@{@"identifier": identifier, @"executablePath": [url.path stringByAppendingPathComponent:@"bin/ruby"]} additionalInfo:@{@"url": url}];
}

- (id)initWithMemento:(NSDictionary *)memento additionalInfo:(NSDictionary *)additionalInfo {
    self = [super initWithMemento:memento additionalInfo:additionalInfo];
    if (self) {
        self.rootUrl = ATInitOrResolveSecurityScopedURL(self.memento, additionalInfo[@"url"], ATSecurityScopedURLOptionsReadWrite);
        [self.rootUrl startAccessingSecurityScopedResource];
    }
    return self;
}

- (NSString *)executablePath {
    return [[self.rootUrl URLByAppendingPathComponent:@"bin/ruby"] path];
}

- (NSString *)basicTitle {
    return @"Custom Ruby";
}

- (NSString *)detailLabel {
    return [self.rootUrl.path stringByAbbreviatingTildeInPathUsingRealHomeDirectory];
}

@end
