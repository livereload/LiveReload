
#import "Action.h"
#import "LRProjectFile.h"
#import "LRCommandLine.h"
#import "LRContextActionType.h"
#import "LRActionVersion.h"
#import "LRActionManifest.h"
#import "LRVersionSpec.h"
#import "LRVersionOption.h"
#import "LRCustomArgumentsOption.h"
#import "Errors.h"
#import "Project.h"
#import "ScriptInvocationStep.h"
#import "Plugin.h"
#import "LRPackage.h"
#import "LRPackageSet.h"
#import "LRVersion.h"
#import "LROperationResult.h"

#import "ATScheduling.h"
#import "ATObservation.h"
#import "ATFunctionalStyle.h"



NSString *const LRActionPrimaryEffectiveVersionDidChangeNotification = @"LRActionPrimaryEffectiveVersionDidChange";



@interface Action ()

@property(nonatomic, strong) ATPathSpec *inputPathSpec;

@end


@implementation Action {
    NSMutableDictionary *_memento;
    NSMutableDictionary *_options;

    ATCoalescedState _effectiveActionComputationState;
}

- (ActionKind)kind {
    return _contextActionType.actionType.kind;
}

- (NSString *)label {
    abort();
}

- (id)initWithContextActionType:(LRContextActionType *)contextActionType memento:(NSDictionary *)memento {
    self = [super init];
    if (self) {
        _contextActionType = contextActionType;
        _project = _contextActionType.project;
        _options = [NSMutableDictionary new];
        [self setMemento:memento];

        [self observeNotification:LRContextActionTypeDidChangeVersionsNotification withSelector:@selector(_updateEffectiveVersion)];
        [self _updateEffectiveVersion];
    }
    return self;
}

- (void)dealloc {
    [self removeAllObservations];
}

- (ActionType *)type {
    return _contextActionType.actionType;
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
    self.primaryVersionSpec = memento[@"version"] ? [LRVersionSpec versionSpecWithString:memento[@"version"] inVersionSpace:self.type.primaryVersionSpace] : [LRVersionSpec stableVersionSpecMatchingAnyVersionInVersionSpace:self.type.primaryVersionSpace];

    NSDictionary *options = memento[@"options"];
    if (options)
        [_options setValuesForKeysWithDictionary:options];
}

- (void)updateMemento:(NSMutableDictionary *)memento {
    memento[@"action"] = self.type.identifier;
    memento[@"enabled"] = (self.enabled ? @1 : @0);
    memento[@"filter"] = self.inputFilterOption.memento;
    memento[@"version"] = self.primaryVersionSpec.stringValue;
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

- (LRTargetResult *)targetForModifiedFiles:(NSArray *)files {
    return nil;
}

- (BOOL)supportsFileTargets {
    return NO;
}

- (LRTargetResult *)fileTargetForRootFile:(LRProjectFile *)file {
    return nil;
}

- (NSArray *)fileTargetsForModifiedFiles:(NSArray *)modifiedFiles {
    if (![self supportsFileTargets])
        return @[];
    NSArray *matchingFiles = [self filesMatchedByInputPathSpecAmongFiles:modifiedFiles type:ATPathSpecEntryTypeFile];
    NSArray *rootFiles = [self.project rootFilesForFiles:matchingFiles];
    NSArray *matchingRootFiles = [self filesMatchedByInputPathSpecAmongFiles:rootFiles type:ATPathSpecEntryTypeFile];
    return [matchingRootFiles arrayByMappingElementsUsingBlock:^id(LRProjectFile *file) {
        return [self fileTargetForRootFile:file];
    }];
}

- (NSArray *)filesMatchedByInputPathSpecAmongFiles:(NSArray *)files type:(ATPathSpecEntryType)type {
    NSMutableArray *result = [[NSMutableArray alloc] initWithCapacity:files.count];
    for (LRProjectFile *file in files) {
        if ([self.inputPathSpec matchesPath:file.relativePath type:type])
            [result addObject:file];
    }
    return [result copy];
}

- (BOOL)inputPathSpecMatchesFiles:(NSArray *)files {
    for (LRProjectFile *file in files) {
        if ([self.inputPathSpec matchesPath:file.relativePath type:ATPathSpecEntryTypeFile])
            return YES;
    }
    return NO;
}

- (NSArray *)pathsMatchedByInputPathSpecAmongFilePaths:(NSArray *)paths {
    return [self.inputPathSpec matchingPathsInArray:paths type:ATPathSpecEntryTypeFile];
}

- (void)analyzeFile:(LRProjectFile *)file inProject:(Project *)project {
}

- (void)compileFile:(LRProjectFile *)file inProject:(Project *)project result:(LROperationResult *)result completionHandler:(dispatch_block_t)completionHandler {
    abort();
}

- (void)handleDeletionOfFile:(LRProjectFile *)file inProject:(Project *)project {
}

- (void)invokeForProject:(Project *)project withModifiedFiles:(NSArray *)files result:(LROperationResult *)result completionHandler:(dispatch_block_t)completionHandler {
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
    [options addObject:[[LRVersionOption alloc] initWithManifest:@{@"id": @"version", @"label": @"Version:"} action:self errorSink:nil]];
    [options addObjectsFromArray:[self.effectiveVersion.manifest createOptionsWithAction:self]];
    [options addObject:[[LRCustomArgumentsOption alloc] initWithManifest:@{@"id": @"custom-args"} action:self errorSink:nil]];
    return [options copy];
}


#pragma mark - Versions

- (void)setPrimaryVersionSpec:(LRVersionSpec *)primaryVersionSpec {
    if (_primaryVersionSpec != primaryVersionSpec && ![_primaryVersionSpec isEqual:primaryVersionSpec]) {
        _primaryVersionSpec = primaryVersionSpec;
        [self didChange];
        [self _updateEffectiveVersion];
    }
}

- (void)_updateEffectiveVersion {
    AT_dispatch_coalesced_with_notifications(&_effectiveActionComputationState, 0, ^(dispatch_block_t done) {
        [self willChangeValueForKey:@"effectiveVersion"];
        _effectiveVersion = [self _computeEffectiveVersion];
        [self didChangeValueForKey:@"effectiveVersion"];
        [self postNotificationName:LRActionPrimaryEffectiveVersionDidChangeNotification];
        done();
    }, ^{
        [_project setAnalysisInProgress:(_effectiveActionComputationState > 0) forTask:self];
    });
}

- (LRActionVersion *)_computeEffectiveVersion {
    NSArray *versions = self.contextActionType.versions;
    for (LRActionVersion *actionVersion in [versions reverseObjectEnumerator]) {
        if ([_primaryVersionSpec matchesVersion:actionVersion.primaryVersion withTag:LRVersionTagUnknown]) {
            return actionVersion;
        }
    }
    return nil;
}

- (NSError *)missingEffectiveVersionError {
    return [NSError errorWithDomain:LRErrorDomain code:LRErrorNoMatchingVersion userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"No available version matched for version spec %@, available versions: %@", self.primaryVersionSpec, [[self.contextActionType.versions valueForKeyPath:@"primaryVersion"] componentsJoinedByString:@", "]]}];
}


#pragma mark - Change notification

- (void)didChange {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"SomethingChanged" object:self];
}


#pragma mark - Configuration

- (void)configureStep:(ScriptInvocationStep *)step {
    step.project = self.contextActionType.project;
    [step addValue:step.project.path forSubstitutionKey:@"project_dir"];

    LRActionManifest *manifest = self.effectiveVersion.manifest;
    step.commandLine = manifest.commandLineSpec;
    [step addValue:self.type.plugin.path forSubstitutionKey:@"plugin"];

    for (LRPackage *package in self.effectiveVersion.packageSet.packages) {
        [step addValue:package.sourceFolderURL.path forSubstitutionKey:package.identifier];
        [step addValue:package.version.description forSubstitutionKey:[NSString stringWithFormat:@"%@.ver", package.identifier]];
    }

    NSMutableArray *additionalArguments = [NSMutableArray new];
    for (LROption *option in [self createOptions]) {
        [additionalArguments addObjectsFromArray:option.commandLineArguments];
    }
    [additionalArguments addObjectsFromArray:self.customArguments];

    [step addValue:[additionalArguments copy] forSubstitutionKey:@"additional"];
}

- (void)configureResult:(LROperationResult *)result {
    LRActionManifest *manifest = self.effectiveVersion.manifest;
    result.errorSyntaxManifest = @{@"errors": manifest.errorSpecs, @"warnings": manifest.warningSpecs};
}

@end
