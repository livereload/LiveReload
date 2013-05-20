
#import "HomebrewRubyInstance.h"
#import "HomebrewContainer.h"


@interface HomebrewRubyInstance ()

@property(nonatomic, __unsafe_unretained) HomebrewContainer *container;
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

- (NSString *)executableURL {
    return [NSURL fileURLWithPath:[self.container.binPath stringByAppendingPathComponent:self.name]];
}

- (NSString *)detailLabel {
    return self.name;
}

@end
