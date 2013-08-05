
#import "RvmRubyInstance.h"
#import "RvmContainer.h"


@interface RvmRubyInstance ()

@property(nonatomic, weak) RvmContainer *container;
@property(nonatomic, strong) NSString *name;

@end


@implementation RvmRubyInstance

- (id)initWithIdentifier:(NSString *)identifier name:(NSString *)name container:(RvmContainer *)container {
    self = [super initWithMemento:@{@"identifier": identifier} additionalInfo:nil];
    if (self) {
        self.container = container;
        self.name = name;
    }
    return self;
}

- (NSString *)basicTitle {
    return @"RVM Ruby";
}

- (NSURL *)executableURL {
    return [NSURL fileURLWithPath:[self.container.binPath stringByAppendingPathComponent:self.name]];
}

- (NSString *)detailLabel {
    return self.name;
}

@end
