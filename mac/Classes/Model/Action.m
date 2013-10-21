
#import "Action.h"
#import "LRFile2.h"
#import "LRCommandLine.h"

#import "LRCheckboxOption.h"
#import "LRTextFieldOption.h"
#import "LRPopUpOption.h"
#import "LRCustomArgumentsOption.h"


@interface Action ()

@property(nonatomic, strong) ATPathSpec *inputPathSpec;

@end


@implementation Action {
    NSMutableDictionary *_memento;
    NSMutableDictionary *_options;
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
        _options = [NSMutableDictionary new];
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

    NSDictionary *options = memento[@"options"];
    if (options)
        [_options setValuesForKeysWithDictionary:options];
}

- (void)updateMemento:(NSMutableDictionary *)memento {
    memento[@"action"] = self.type.identifier;
    memento[@"enabled"] = (self.enabled ? @1 : @0);
    memento[@"filter"] = self.inputFilterOption.memento;
    if (_options.count > 0)
        memento[@"options"] = [NSDictionary dictionaryWithDictionary:_options];
    else
        [memento removeObjectForKey:@"options"];
}

- (void)setEnabled:(BOOL)enabled {
    if (_enabled != enabled) {
        _enabled = enabled;
        [self didChange];
    }
}

- (void)setInputFilterOption:(FilterOption *)inputFilterOption {
    if (_inputFilterOption != inputFilterOption) {
        _inputFilterOption = inputFilterOption;
        [self updateInputPathSpec];
        [self didChange];
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

- (BOOL)shouldInvokeForFile:(LRFile2 *)file {
    return [self.inputPathSpec matchesPath:file.relativePath type:ATPathSpecEntryTypeFile];
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


#pragma mark - Custom options

- (NSArray *)customArguments {
    return _options[@"custom-args"] ?: @[];
}

- (void)setCustomArguments:(NSArray *)customArguments {
    if (customArguments.count == 0)
        customArguments = nil;
    [self setOptionValue:customArguments forKey:@"custom-args"];
}

- (NSString *)customArgumentsString {
    return [self.customArguments quotedArgumentStringUsingBourneQuotingStyle];
}

- (void)setCustomArgumentsString:(NSString *)customArgumentsString {
    self.customArguments = [customArgumentsString argumentsArrayUsingBourneQuotingStyle];
}

- (id)optionValueForKey:(NSString *)key {
    return _options[key];
}

- (void)setOptionValue:(id)value forKey:(NSString *)key {
    if (value) {
        if (_options[key] != value) {
            _options[key] = value;
            [self didChange];
        }
    } else {
        if ([_options objectForKey:key]) {
            [_options removeObjectForKey:key];
            [self didChange];
        }
    }
}


#pragma mark - Options

- (NSArray *)createOptions {
    NSMutableArray *options = [NSMutableArray new];

    [options addObject:[[LRCheckboxOption alloc] initWithOptionManifest:@{@"id": @"foo-bar", @"label": @"Foo Bar", @"args": @"--foo-bar"} action:self]];

    [options addObject:[[LRTextFieldOption alloc] initWithOptionManifest:@{@"id": @"foo-boz", @"label": @"Bozz:", @"placeholder": @"boo boo", @"args": @"--foo-boz $(value)"} action:self]];

    [options addObject:[[LRPopUpOption alloc] initWithOptionManifest:@{@"id": @"fubar", @"label": @"Fubar:", @"items": @[@{@"id": @"abc", @"label": @"Ab C", @"args": @""}, @{@"id": @"def", @"label": @"dEF", @"args": @"--fubar-def"}]} action:self]];

    [options addObject:[[LRCustomArgumentsOption alloc] initWithOptionManifest:@{@"id": @"custom-args"} action:self]];

    return [options copy];
}


#pragma mark - Change notification

- (void)didChange {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"SomethingChanged" object:self];
}

@end
