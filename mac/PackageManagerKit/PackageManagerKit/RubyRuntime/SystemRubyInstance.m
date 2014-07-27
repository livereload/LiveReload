
#import "SystemRubyInstance.h"
@import LRCommons;


@interface SystemRubyInstance ()

@property(nonatomic, strong) NSURL *executableURL;

@end


@implementation SystemRubyInstance

@synthesize executableURL=_executableURL;

- (id)initWithIdentifier:(NSString *)identifier executableURL:(NSURL *)executableURL {
    return [self initWithMemento:nil additionalInfo:@{@"identifier": identifier, @"executableURL": executableURL}];
}

- (id)initWithMemento:(NSDictionary *)memento additionalInfo:(NSDictionary *)additionalInfo {
    self = [super initWithMemento:memento additionalInfo:additionalInfo];
    if (self) {
        self.identifier = additionalInfo[@"identifier"];
        self.executableURL = additionalInfo[@"executableURL"];
    }
    return self;
}

- (NSString *)basicTitle {
    return @"System Ruby";
}

- (NSString *)detailLabel {
    return [self.executablePath stringByAbbreviatingTildeInPathUsingRealHomeDirectory];
}

@end
