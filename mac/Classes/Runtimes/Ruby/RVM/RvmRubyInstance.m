
#import "RvmRubyInstance.h"
#import "RvmContainer.h"

@implementation RvmRubyInstance

- (id)initWithIdentifier:(NSString *)identifier container:(RvmContainer *)container {
//    NSString *rootPath = [container.rubiesPath stringByAppendingPathComponent:identifier];
    NSString *execPath = [container.binPath stringByAppendingPathComponent:identifier];

    self = [super initWithMemento:@{@"identifier": identifier, @"executablePath": execPath, @"basicTitle": identifier} additionalInfo:nil];
    if (self) {
    }
    return self;
}

- (NSString *)basicTitle {
    return @"RVM Ruby";
}

- (NSString *)detailLabel {
    return self.memento[@"identifier"];
}

@end
