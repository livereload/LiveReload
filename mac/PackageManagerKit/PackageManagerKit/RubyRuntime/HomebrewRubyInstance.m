
#import "HomebrewRubyInstance.h"
#import "HomebrewContainer.h"
@import LRCommons;


@interface HomebrewRubyInstance ()

@property(nonatomic, weak) HomebrewContainer *container;
@property(nonatomic, strong) NSString *name;

@end


@implementation HomebrewRubyInstance

- (id)initWithIdentifier:(NSString *)identifier name:(NSString *)name container:(HomebrewContainer *)container {
    self = [super initWithMemento:@{@"identifier": identifier} additionalInfo:nil];
    if (self) {
        self.container = container;
        self.name = name;
    }
    return self;
}

- (NSString *)basicTitle {
    return @"Homebrew Ruby";
}

- (NSURL *)rootURL {
    return [self.container.rubiesUrl URLByAppendingPathComponent:self.name];
}

- (NSURL *)executableURL {
    return [self.rootURL URLByAppendingPathComponent:@"bin/ruby"];
}

- (NSString *)detailLabel {
    return [[self.rootURL path] stringByAbbreviatingTildeInPathUsingRealHomeDirectory];
}

@end
