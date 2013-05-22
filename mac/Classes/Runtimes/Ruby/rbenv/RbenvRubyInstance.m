
#import "RbenvRubyInstance.h"
#import "RbenvContainer.h"


@interface RbenvRubyInstance ()

@property(nonatomic, __unsafe_unretained) RbenvContainer *container;
@property(nonatomic, strong) NSString *name;

@end


@implementation RbenvRubyInstance

- (id)initWithIdentifier:(NSString *)identifier name:(NSString *)name container:(RbenvContainer *)container {
    self = [super initWithMemento:@{@"identifier": identifier} additionalInfo:nil];
    if (self) {
        self.container = container;
        self.name = name;
    }
    return self;
}

- (NSString *)basicTitle {
    return @"rbenv ruby";
}

- (NSURL *)rootURL {
    return [NSURL fileURLWithPath:[self.container.rubiesPath stringByAppendingPathComponent:self.name]];
}

- (NSURL *)executableURL {
    return [self.rootURL URLByAppendingPathComponent:@"bin/ruby"];
}

- (NSString *)detailLabel {
    return self.name;
}

@end
