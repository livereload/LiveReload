
#import "Action.h"


@implementation Action {
    NSMutableDictionary *_memento;
}

+ (NSString *)typeIdentifier {
    abort();
}

+ (ActionKind)kind {
    abort();
}

- (NSString *)typeIdentifier {
    return [[self class] typeIdentifier];
}

- (ActionKind)kind {
    return [[self class] kind];
}

- (NSString *)label {
    abort();
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
    self.inputFilterOption = [FilterOption filterOptionWithMemento:(memento[@"filter"] ?: @"subdir:.")];
}

- (void)updateMemento:(NSMutableDictionary *)memento {
    memento[@"action"] = self.typeIdentifier;
    memento[@"enabled"] = (self.enabled ? @1 : @0);
    memento[@"filter"] = self.inputFilterOption.memento;
}

- (void)setEnabled:(BOOL)enabled {
    if (_enabled != enabled) {
        _enabled = enabled;
        [[NSNotificationCenter defaultCenter] postNotificationName:@"SomethingChanged" object:self];
    }
}

- (void)setInputFilterOption:(FilterOption *)inputFilterOption {
    if (_inputFilterOption != inputFilterOption) {
        _inputFilterOption = inputFilterOption;
        [[NSNotificationCenter defaultCenter] postNotificationName:@"SomethingChanged" object:self];
    }
}

- (ATPathSpec *)inputPathSpec {
    return _inputFilterOption.pathSpec;
}

- (BOOL)isNonEmpty {
    return YES;
}

- (BOOL)shouldInvokeForModifiedFiles:(NSSet *)paths inProject:(Project *)project {
    for (NSString *path in paths) {
        if ([self.inputPathSpec matchesPath:path type:ATPathSpecEntryTypeFile])
            return YES;
    }
    return NO;
}

- (void)analyzeFile:(LRFile2 *)file inProject:(Project *)project {
}

- (void)compileFile:(LRFile2 *)file inProject:(Project *)project completionHandler:(UserScriptCompletionHandler)completionHandler {
    abort();
}

- (void)invokeForProjectAtPath:(NSString *)projectPath withModifiedFiles:(NSSet *)paths completionHandler:(UserScriptCompletionHandler)completionHandler {
    abort();
}

@end
