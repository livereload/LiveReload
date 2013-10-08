
#import "Action.h"


@interface Action ()

@property(nonatomic, strong) ATPathSpec *inputPathSpec;

@end


@implementation Action {
    NSMutableDictionary *_memento;
}

+ (void)validateActionType:(ActionType *)actionType {
    // nothing to do here
}

- (ActionKind)kind {
    return _type.kind;
}

- (NSString *)label {
    abort();
}

- (id)initWithType:(ActionType *)type memento:(NSDictionary *)memento {
    self = [super init];
    if (self) {
        _type = type;
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
    memento[@"action"] = self.type.identifier;
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
        [self updateInputPathSpec];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"SomethingChanged" object:self];
    }
}

- (void)setIntrinsicInputPathSpec:(ATPathSpec *)intrinsicInputPathSpec {
    if (_intrinsicInputPathSpec != intrinsicInputPathSpec) {
        _intrinsicInputPathSpec = intrinsicInputPathSpec;
        [self updateInputPathSpec];
    }
}

- (void)updateInputPathSpec {
    ATPathSpec *spec = _inputFilterOption.pathSpec;
    if (spec) {
        if (_intrinsicInputPathSpec) {
            spec = [ATPathSpec pathSpecMatchingIntersectionOf:@[spec, _intrinsicInputPathSpec]];
        }
    }
    self.inputPathSpec = spec;
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
