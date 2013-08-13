
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
    self.enabled = [(memento[@"enabled"] ?: @YES) boolValue];
}

- (void)updateMemento:(NSMutableDictionary *)memento {
    memento[@"action"] = self.typeIdentifier;
    memento[@"enabled"] = (self.enabled ? @1 : @0);
}

- (void)setEnabled:(BOOL)enabled {
    if (_enabled != enabled) {
        _enabled = enabled;
        [[NSNotificationCenter defaultCenter] postNotificationName:@"SomethingChanged" object:self];
    }
}

- (BOOL)isNonEmpty {
    return YES;
}

@end


@implementation CustomCommandAction

+ (NSString *)typeIdentifier {
    return @"command";
}

- (void)loadFromMemento:(NSDictionary *)memento {
    [super loadFromMemento:memento];
    self.command = memento[@"command"] ?: @"";
}

- (void)updateMemento:(NSMutableDictionary *)memento {
    [super updateMemento:memento];
    memento[@"command"] = self.command;
}

- (void)setCommand:(NSString *)command {
    if (_command != command) {
        _command = command;
        [[NSNotificationCenter defaultCenter] postNotificationName:@"SomethingChanged" object:self];
    }
}

- (BOOL)isNonEmpty {
    return _command.length > 0;
}

+ (NSSet *)keyPathsForValuesAffectingNonEmpty {
    return [NSSet setWithArray:@[@"command"]];
}

@end


@implementation UserScriptAction


+ (NSString *)typeIdentifier {
    return @"script";
}

@end
