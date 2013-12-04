
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

- (NSURL *)environmentURL {
    return [self.container.environmentsURL URLByAppendingPathComponent:self.name];
}

- (NSString *)detailLabel {
    return self.name;
}


#pragma mark - Gems

- (NSURL *)gemExecutableURL {
    NSURL *dir = [self.executableURL URLByDeletingLastPathComponent];
    NSString *fileName = [self.executableURL lastPathComponent];
    return [dir URLByAppendingPathComponent:[NSString stringWithFormat:@"gem-%@", fileName]];
}

- (NSArray *)launchArgumentsWithAdditionalRuntimeContainers:(NSArray *)additionalRuntimeContainers environment:(NSMutableDictionary *)environment {

    NSString *gemPath = [[additionalRuntimeContainers valueForKeyPath:@"folderURL.path"] componentsJoinedByString:@":"];

    NSString *command;
    if (gemPath.length > 0) {
        command = [NSString stringWithFormat:@"source '%@'; export GEM_PATH=\"%@:$GEM_PATH\"; exec ruby \"$@\"", self.environmentURL.path, gemPath];
    } else {
        command = [NSString stringWithFormat:@"source '%@'; exec ruby \"$@\"", self.environmentURL.path];
    }

    return @[@"/bin/bash", @"-c", command, @"--"];
}

@end
