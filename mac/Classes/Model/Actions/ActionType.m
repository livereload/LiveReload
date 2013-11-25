
#import "ActionType.h"
#import "Action.h"
#import "Errors.h"
#import "Plugin.h"
#import "LROption+Factory.h"
#import "LRPackageManager.h"
#import "LRPackageReference.h"
#import "LRPackageResolutionContext.h"
#import "LRPackageSet.h"

#import "LRManifestLayer.h"
#import "LRActionVersion.h"
#import "LRActionManifest.h"
#import "LRAssetPackageConfiguration.h"

#import "ATFunctionalStyle.h"



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


@implementation ActionType {
    NSMutableArray *_errors;
    NSArray *_manifestLayers;
    NSArray *_packageConfigurations;
}

- (instancetype)initWithManifest:(NSDictionary *)manifest errorSink:(id<LRManifestErrorSink>)errorSink {
    if (self = [super initWithManifest:manifest errorSink:errorSink]) {
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
                                         @"objc_class":    @"FilterAction",
                                         @"objc_rowClass": @"FilterActionRow",
                                         },
                                 @"compile-file": @{
                                         @"kind": @"compiler",
                                         @"objc_class":    @"CompileFileAction",
                                         @"objc_rowClass": @"CompileFileActionRow",
                                         },
                                 };

    NSDictionary *options = self.manifest;

    NSString *typeName = self.manifest[@"type"];
    if (typeName) {
        NSDictionary *typeOptions = knownTypes[typeName];

        NSMutableDictionary *mergedOptions = [NSMutableDictionary new];
        [mergedOptions addEntriesFromDictionary:typeOptions];
        [mergedOptions addEntriesFromDictionary:options];
        options = [mergedOptions copy];
    }

    _kind = LRActionKindFromString(options[@"kind"] ?: @"");

    NSString *actionClassName = options[@"objc_class"] ?: @"";
    NSString *rowClassName = options[@"objc_rowClass"] ?: @"";

    _actionClass = NSClassFromString(actionClassName);
    _rowClass = NSClassFromString(rowClassName);

    if (_identifier.length == 0)
        [self addErrorMessage:@"'id' attribute is required"];

    if (_kind == ActionKindUnknown)
        [self addErrorMessage:[NSString stringWithFormat:@"'kind' attribute is required and must be one of %@", LRValidActionKindStrings()]];
    
    if (!_actionClass)
        [self addErrorMessage:[NSString stringWithFormat:@"Cannot find action class '%@'", actionClassName]];
    if (!_rowClass)
        [self addErrorMessage:[NSString stringWithFormat:@"Cannot find row class '%@'", rowClassName]];
    
    _manifestLayers = [self.manifest[@"defaults"] arrayByMappingElementsUsingBlock:^id(NSDictionary *info) {
        return [[LRManifestLayer alloc] initWithManifest:info errorSink:self];
    }];

    if ([_identifier isEqualToString:@"less"]) {
        NSLog(@"LESS");
    }

    NSMutableArray *packageConfigurations = [NSMutableArray new];
    NSArray *packageConfigurationManifests = self.manifest[@"packageConfigurations"];
    if (![packageConfigurationManifests isKindOfClass:NSArray.class] || packageConfigurationManifests.count == 0) {
        [self addErrorMessage:@"No package configurations defined"];
    } else {
        for (NSDictionary *packageConfigurationManifest in packageConfigurationManifests) {
            if (![packageConfigurationManifest isKindOfClass:NSDictionary.class])
                [self addErrorMessage:@"Every package configuration must be a dictionary"];
            [packageConfigurations addObject:[[LRAssetPackageConfiguration alloc] initWithManifest:packageConfigurationManifest errorSink:self]];
        }
    }
    _packageConfigurations = [packageConfigurations copy];

    [self _updateAvailableVersions];
    // TODO: subscribe and update on events
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 500 * NSEC_PER_MSEC), dispatch_get_main_queue(), ^{
        [self _updateAvailableVersions];
    });

}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@ '%@' (%@, %@)", LRStringFromActionKind(_kind), _identifier, NSStringFromClass(_actionClass), NSStringFromClass(_rowClass)];
}

- (Action *)newInstanceWithMemento:(NSDictionary *)memento {
    return [[_actionClass alloc] initWithType:self memento:memento];
}

- (LRActionManifest *)_actionManifestForPackageSet:(LRPackageSet *)packageSet {
    NSMutableArray *layers = [NSMutableArray new];
    for (LRManifestLayer *layer in layers) {
        if ([packageSet matchesAllPackageReferencesInArray:layer.packageReferences]) {
            [layers addObject:layer];
        }
    }
    return [[LRActionManifest alloc] initWithLayers:layers];
}

- (void)_updateAvailableVersions {
    if (!self.valid) {
        _versions = @[];
        return;
    }

    // TODO: this should depend on the selected package
    LRPackageResolutionContext *resolutionContext = [LRPackageResolutionContext new];

    NSMutableArray *packageSets = [NSMutableArray new];
    for (LRAssetPackageConfiguration *configuration in _packageConfigurations) {
        [packageSets addObjectsFromArray:[resolutionContext packageSetsMatchingConfiguration:configuration]];
    }

    NSMutableArray *versions = [NSMutableArray new];
    for (LRPackageSet *packageSet in packageSets) {
        LRActionManifest *manifest = [self _actionManifestForPackageSet:packageSet];
        LRActionVersion *version = [[LRActionVersion alloc] initWithType:self manifest:manifest packageSet:packageSet];
        [versions addObject:version];
    }
    _versions = versions;
}

@end
