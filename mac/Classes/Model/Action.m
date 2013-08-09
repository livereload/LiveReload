
#import "Action.h"

@implementation Action {
    NSMutableDictionary *_memento;
}

+ (NSString *)typeIdentifier {
    abort();
}

- (NSDictionary *)memento {
    [self updateMemento:_memento];
    return _memento;
}

- (void)setMemento:(NSDictionary *)memento {
    _memento = [memento mutableCopy];
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

@end


@implementation UserScriptAction


+ (NSString *)typeIdentifier {
    return @"script";
}

@end
