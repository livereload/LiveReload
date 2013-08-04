
#import "CustomRubyInstance.h"
#import "ATGlobals.h"


@interface CustomRubyInstance ()

@property(nonatomic, strong) NSURL *rootUrl;

@end


@implementation CustomRubyInstance

- (id)initWithURL:(NSURL *)url {
    NSString *identifier = [NSString stringWithFormat:@"custom:%@", [[url path] stringByAbbreviatingTildeInPathUsingRealHomeDirectory]];
    return [self initWithMemento:@{@"identifier": identifier} additionalInfo:@{@"url": url}];
}

- (id)initWithMemento:(NSDictionary *)memento additionalInfo:(NSDictionary *)additionalInfo {
    self = [super initWithMemento:memento additionalInfo:additionalInfo];
    if (self) {
        self.rootUrl = ATInitOrResolveSecurityScopedURL(self.memento, additionalInfo[@"url"], ATSecurityScopedURLOptionsReadWrite);
        [self.rootUrl startAccessingSecurityScopedResource];
    }
    return self;
}

- (NSURL *)executableURL {
    return [self.rootUrl URLByAppendingPathComponent:@"bin/ruby"];
}

- (NSString *)basicTitle {
    return @"Custom Ruby";
}

- (NSString *)titleDetail {
    return [NSString stringWithFormat:@"at %@", [self.rootUrl.path stringByAbbreviatingTildeInPathUsingRealHomeDirectory]];
}

- (NSString *)detailLabel {
    return [self.rootUrl.path stringByAbbreviatingTildeInPathUsingRealHomeDirectory];
}

- (BOOL)isPersistent {
    return YES;
}

@end
