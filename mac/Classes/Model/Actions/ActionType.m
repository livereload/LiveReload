
#import "ActionType.h"
#import "Action.h"
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
    NSArray *_packageConfigurations;
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
                                         @"objc_class":    @"FilterAction",
                                         @"objc_rowClass": @"FilterActionRow",
                                         },
                                 @"compile-file": @{
                                         @"kind": @"compiler",
                                         @"objc_class":    @"CompileFileAction",
                                         @"objc_rowClass": @"CompileFileActionRow",
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

    NSString *actionClassName = manifest[@"objc_class"] ?: @"";
    NSString *rowClassName = manifest[@"objc_rowClass"] ?: @"";

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

    LRPackageManager *packageManager = [AppState sharedAppState].packageManager;
    NSArray *versionInfoLayers = [(self.manifest[@"versionInfo"] ?: @{}) arrayByMappingEntriesUsingBlock:^id(NSString *packageRefString, NSDictionary *info) {
        LRPackageReference *reference = [packageManager packageReferenceWithString:packageRefString];
        return [[LRManifestLayer alloc] initWithManifest:info requiredPackageReferences:@[reference] errorSink:self];
    }];
    
    _manifestLayers = [[self.manifest[@"defaults"] arrayByMappingElementsUsingBlock:^id(NSDictionary *info) {
        return [[LRManifestLayer alloc] initWithManifest:info errorSink:self];
    }] arrayByAddingObjectsFromArray:versionInfoLayers];

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

    if (_packageConfigurations.count == 0)
        _primaryVersionSpace = nil;
    else {
        LRAssetPackageConfiguration *configuration = [_packageConfigurations firstObject];
        LRPackageReference *reference = [configuration.packageReferences firstObject];
        _primaryVersionSpace = reference.type.versionSpace;
    }
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@ '%@' (%@, %@)", LRStringFromActionKind(_kind), _identifier, NSStringFromClass(_actionClass), NSStringFromClass(_rowClass)];
}

@end
