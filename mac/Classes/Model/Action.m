
#import "Action.h"

@implementation Action {
    NSMutableDictionary *_memento;
}

+ (NSString *)typeIdentifier {
    abort();
}

- (NSString *)typeIdentifier {
    return [[self class] typeIdentifier];
}

- (id)initWithMemento:(NSDictionary *)memento {
    self = [super init];
    if (self) {
        [self setMemento:memento];
    }
    return self;
}

- (NSDictionary *)memento {
    [self updateMemento:_memento];
    return _memento;
}

- (void)setMemento:(NSDictionary *)memento {
    _memento = [(memento ?: @{}) mutableCopy];
    [self loadFromMemento:_memento];
}

- (void)loadFromMemento:(NSDictionary *)memento {
}

- (void)updateMemento:(NSMutableDictionary *)memento {
}

@end


@implementation CustomCommandAction

+ (NSString *)typeIdentifier {
    return @"command";
}

- (void)loadFromMemento:(NSDictionary *)memento {
    self.command = memento[@"command"] ?: @"";
}

- (void)updateMemento:(NSMutableDictionary *)memento {
    memento[@"command"] = self.command;
}

- (void)setCommand:(NSString *)command {
    _command = command;
}

@end


@implementation UserScriptAction


+ (NSString *)typeIdentifier {
    return @"script";
}

@end
