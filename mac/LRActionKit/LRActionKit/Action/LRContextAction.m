@import LRCommons;
@import PiiVersionKit;
@import PackageManagerKit;

#import "LRContextAction.h"
#import "Action.h"
#import "LRActionVersion.h"
#import "LRActionManifest.h"
#import "LRManifestLayer.h"
#import "LRVersionSpec.h"
#import "LRAssetPackageConfiguration.h"
#import "LRActionKit-Swift.h"


NSString *const LRContextActionDidChangeVersionsNotification = @"LRContextActionDidChangeVersions";


@interface LRContextAction ()

@end


@implementation LRContextAction {
    ATCoalescedState _updateState;
}

- (id)initWithAction:(Action *)action project:(id<ProjectContext>)project resolutionContext:(LRPackageResolutionContext *)resolutionContext {
    self = [super init];
    if (self) {
        _action = action;
        _project = project;
        _resolutionContext = resolutionContext;

        [self observeNotification:LRPackageContainerDidChangePackageListNotification withSelector:@selector(_updateAvailableVersions)];
        [self _updateAvailableVersions];
    }
    return self;
}

- (void)dealloc {
    [self removeAllObservations];
}

- (void)_updateAvailableVersions {
    AT_dispatch_coalesced_with_notifications(&_updateState, 0, ^(dispatch_block_t done) {
        _versions = [[self _computeAvailableVersions] copy];
        _versionSpecs = [[self _computeAvailableVersionSpecs] copy];
        [self postNotificationName:LRContextActionDidChangeVersionsNotification];
        done();
    }, ^{
        [_project setAnalysisInProgress:(_updateState > 0) forTask:self];
    });
}

- (NSArray *)_computeAvailableVersions {
    if (!_action.valid) {
        return @[];
    }

    NSMutableArray *packageSets = [NSMutableArray new];
    for (LRAssetPackageConfiguration *configuration in _action.packageConfigurations) {
        [packageSets addObjectsFromArray:[_resolutionContext packageSetsMatchingPackageReferences:configuration.packageReferences]];
    }

    NSMutableArray *versions = [NSMutableArray new];
    for (LRPackageSet *packageSet in packageSets) {
        LRActionManifest *manifest = [self _actionManifestForPackageSet:packageSet];
        if (!manifest.valid) {
            NSLog(@"ContextAction(%@) skipping version %@ b/c of invalid manifest: %@", _action.name, packageSet.primaryPackage, manifest.errors);
        } else {
            LRActionVersion *version = [[LRActionVersion alloc] initWithType:_action manifest:manifest packageSet:packageSet];
            [versions addObject:version];
        }
    }
    [versions sortUsingComparator:^NSComparisonResult(LRActionVersion *obj1, LRActionVersion *obj2) {
        return [obj1.primaryVersion compare:obj2.primaryVersion];
    }];
    return versions;
}

- (NSArray *)_computeAvailableVersionSpecs {
    NSMutableArray *specs = [NSMutableArray new];
    NSMutableSet *set = [NSMutableSet new];

    void (^addSpec)(LRActionVersion *actionVersion, LRVersionSpec *versionSpec) = ^(LRActionVersion *actionVersion, LRVersionSpec *versionSpec) {
        if (![set containsObject:versionSpec]) {
            versionSpec.changeLogSummary = actionVersion.manifest.changeLogSummary;
            [set addObject:versionSpec];
            [specs addObject:versionSpec];
        }
    };

    for (LRActionVersion *actionVersion in _versions) {
        addSpec(actionVersion, [LRVersionSpec stableVersionSpecWithMajorFromVersion:actionVersion.primaryVersion]);
        addSpec(actionVersion, [LRVersionSpec versionSpecMatchingMajorMinorFromVersion:actionVersion.primaryVersion]);
        addSpec(actionVersion, [LRVersionSpec versionSpecMatchingVersion:actionVersion.primaryVersion]);
    }

    [specs addObject:[LRVersionSpec stableVersionSpecMatchingAnyVersionInVersionSpace:_action.primaryVersionSpace]];

    return specs;
}

- (void)_enumerateVersionSpecsForVersion:(LRActionVersion *)actionVersion block:(void(^)(LRVersionSpec *versionSpec))addSpec {
}

- (LRActionManifest *)_actionManifestForPackageSet:(LRPackageSet *)packageSet {
    NSMutableArray *layers = [NSMutableArray new];
    for (LRManifestLayer *layer in _action.manifestLayers) {
        if ([packageSet matchesAllPackageReferencesInArray:layer.packageReferences]) {
            [layers addObject:layer];
        }
    }
    return [[LRActionManifest alloc] initWithLayers:layers];
}

- (Rule *)newInstanceWithMemento:(NSDictionary *)memento {
    return [[_action.actionClass alloc] initWithContextAction:self memento:memento];
}

@end
