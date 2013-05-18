
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

@end
