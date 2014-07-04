
#import "Action.h"
#import "LiveReload-Swift-x.h"
#import "Errors.h"
#import "Plugin.h"
#import "LROption+Factory.h"
#import "AppState.h"
#import "LRPackageManager.h"
#import "LRPackageReference.h"
#import "LRPackageResolutionContext.h"
#import "LRPackageSet.h"
#import "LRPackageType.h"

#import "LRManifestLayer.h"
#import "LRActionVersion.h"
#import "LRActionManifest.h"
#import "LRAssetPackageConfiguration.h"

#import "ATFunctionalStyle.h"

// for .class ref only
#import "CompileFileRuleRow.h"
#import "FilterRuleRow.h"
#import "CustomCommandRuleRow.h"
#import "UserScriptRuleRow.h"



static NSString *ActionKindNames[] = {
    @"unknown",
    @"compiler",
    @"filter",
    @"postproc",
};

ActionKind LRActionKindFromString(NSString *kindString) {
    static NSDictionary *map;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        map = @{
                @"compiler": @(ActionKindCompiler),
                @"filter": @(ActionKindFilter),
                @"postproc": @(ActionKindPostproc),
                };
    });
    return [map[kindString] intValue];  // gives 0 aka ActionKindUnknown for unknown names
}

NSString *LRStringFromActionKind(ActionKind kind) {
    NSCParameterAssert(kind < kActionKindCount);
    return ActionKindNames[kind];
}

NSArray *LRValidActionKindStrings() {
    return [NSArray arrayWithObjects:ActionKindNames+1 count:kActionKindCount-1];
}


@implementation Action {
    NSMutableArray *_errors;
    NSArray *_packageConfigurations;
    NSString *_fakeChangeExtension;
}

- (instancetype)initWithManifest:(NSDictionary *)manifest plugin:(Plugin *)plugin {
    if (self = [super initWithManifest:manifest errorSink:plugin]) {
        _plugin = plugin;
        [self initializeWithOptions];
    }
    return self;
}

- (void)initializeWithOptions {
    _identifier = [self.manifest[@"id"] copy] ?: @"";
    _name = [self.manifest[@"name"] copy] ?: _identifier;

    NSDictionary *knownTypes = @{
                                 @"filter": @{
                                         @"kind": @"filter",
                                         @"objc_class": [FilterRule class],
                                         @"objc_rowClass": [FilterRuleRow class],
                                     },
                                 @"compile-file": @{
                                         @"kind": @"compiler",
                                         @"objc_class": [CompileFileRule class],
                                         @"objc_rowClass": [CompileFileRuleRow class],
                                     },
                                 @"compile-folder": @{
                                         @"kind": @"postproc",
                                         @"objc_class": [CompileFolderRule class],
                                         @"objc_rowClass": [FilterRuleRow class],
                                     },
                                 @"run-tests": @{
                                         @"kind": @"postproc",
                                         @"objc_class":    [RunTestsRule class],
                                         @"objc_rowClass": [FilterRuleRow class],
                                     },
                                 @"custom-command": @{
                                         @"kind": @"postproc",
                                         @"objc_class": [CustomCommandRule class],
                                         @"objc_rowClass": [CustomCommandRuleRow class],
                                     },
                                 @"user-script": @{
                                         @"kind": @"postproc",
                                         @"objc_class": [UserScriptRule class],
                                         @"objc_rowClass": [UserScriptRuleRow class],
                                     },
                                 };

    NSDictionary *manifest = self.manifest;

    NSString *typeName = self.manifest[@"type"];
    if (typeName) {
        NSDictionary *defaultTypeManifest = knownTypes[typeName];

        NSMutableDictionary *mergedOptions = [NSMutableDictionary new];
        [mergedOptions addEntriesFromDictionary:defaultTypeManifest];
        [mergedOptions addEntriesFromDictionary:manifest];
        manifest = [mergedOptions copy];
    }

    _kind = LRActionKindFromString(manifest[@"kind"] ?: @"");

    _actionClass = manifest[@"objc_class"];
    _rowClass = manifest[@"objc_rowClass"];

    if (_identifier.length == 0)
        [self addErrorMessage:@"'id' attribute is required"];

    if (_kind == ActionKindUnknown)
        [self addErrorMessage:[NSString stringWithFormat:@"'kind' attribute is required and must be one of %@", LRValidActionKindStrings()]];

    LRPackageManager *packageManager = [AppState sharedAppState].packageManager;
    NSArray *versionInfoLayers = [(self.manifest[@"versionInfo"] ?: @{}) arrayByMappingEntriesUsingBlock:^id(NSString *packageRefString, NSDictionary *info) {
        if ([packageRefString hasPrefix:@"__"])
            return nil;
        LRPackageReference *reference = [packageManager packageReferenceWithString:packageRefString];
        return [[LRManifestLayer alloc] initWithManifest:info requiredPackageReferences:@[reference] errorSink:self];
    }];
    
    _manifestLayers = [[self.manifest[@"info"] arrayByMappingElementsUsingBlock:^id(NSDictionary *info) {
        return [[LRManifestLayer alloc] initWithManifest:info errorSink:self];
    }] arrayByAddingObjectsFromArray:versionInfoLayers];

    NSMutableArray *packageConfigurations = [NSMutableArray new];
    NSArray *packageConfigurationManifests = self.manifest[@"packages"];
    if (packageConfigurationManifests && ![packageConfigurationManifests isKindOfClass:NSArray.class]) {
        [self addErrorMessage:@"Invalid type of 'packages' key"];
    } else {
        for (NSArray *packagesInfo in packageConfigurationManifests) {
            if (![packagesInfo isKindOfClass:NSArray.class])
                [self addErrorMessage:@"Every package configuration must be an array"];
            [packageConfigurations addObject:[[LRAssetPackageConfiguration alloc] initWithManifest:@{@"packages": packagesInfo} errorSink:self]];
        }
    }
    _packageConfigurations = [packageConfigurations copy];

    if (_packageConfigurations.count == 0)
        _primaryVersionSpace = nil;
    else {
        LRAssetPackageConfiguration *configuration = [_packageConfigurations firstObject];
        LRPackageReference *reference = [configuration.packageReferences firstObject];
        _primaryVersionSpace = reference.type.versionSpace;
    }

    NSString *inputPathSpecString = self.manifest[@"input"];
    if (inputPathSpecString) {
        _combinedIntrinsicInputPathSpec = [ATPathSpec pathSpecWithString:inputPathSpecString syntaxOptions:ATPathSpecSyntaxFlavorExtended];
    } else {
        _combinedIntrinsicInputPathSpec = [ATPathSpec emptyPathSpec];
    }

    NSString *outputSpecString = self.manifest[@"output"];

    // fake-change mode support is currently hard-coded to target compilers that produce CSS files
    // (everything else triggers a full page reload anyway)
    if ([outputSpecString isEqualToString:@"*.css"]) {
        _fakeChangeExtension = @"css";
    }
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@ '%@' (%@, %@)", LRStringFromActionKind(_kind), _identifier, NSStringFromClass(_actionClass), NSStringFromClass(_rowClass)];
}

- (NSString *)fakeChangeDestinationNameForSourceFile:(LRProjectFile *)file {
    if (_fakeChangeExtension) {
        NSString *relativePath = file.relativePath;
        if (![[relativePath pathExtension] isEqualToString:_fakeChangeExtension]) {
            return [[relativePath stringByDeletingPathExtension] stringByAppendingPathExtension:_fakeChangeExtension];
        }
    }
    return nil;
}

@end
