
#import "LRContextActionType.h"
#import "ActionType.h"
#import "LRPackageResolutionContext.h"
#import "LRPackageContainer.h"
#import "LRPackageSet.h"
#import "LRActionVersion.h"
#import "LRActionManifest.h"
#import "LRManifestLayer.h"
#import "Action.h"
#import "LRVersionSpec.h"

#import "ATObservation.h"
#import "ATScheduling.h"


NSString *const LRContextActionTypeDidChangeVersionsNotification = @"LRContextActionTypeDidChangeVersions";


@interface LRContextActionType ()

@end


@implementation LRContextActionType {
    ATCoalescedState _updateState;
}

- (id)initWithActionType:(ActionType *)actionType resolutionContext:(LRPackageResolutionContext *)resolutionContext {
    self = [super init];
    if (self) {
        _actionType = actionType;
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
    AT_dispatch_coalesced(&_updateState, 0, ^(dispatch_block_t done) {
        _versions = [[self _computeAvailableVersions] copy];
        _versionSpecs = [[self _computeAvailableVersionSpecs] copy];
        [self postNotificationName:LRContextActionTypeDidChangeVersionsNotification];
        done();
    });
}

- (NSArray *)_computeAvailableVersions {
    if (!_actionType.valid) {
        return @[];
    }

    NSMutableArray *packageSets = [NSMutableArray new];
    for (LRAssetPackageConfiguration *configuration in _actionType.packageConfigurations) {
        [packageSets addObjectsFromArray:[_resolutionContext packageSetsMatchingConfiguration:configuration]];
    }

    NSMutableArray *versions = [NSMutableArray new];
    for (LRPackageSet *packageSet in packageSets) {
        LRActionManifest *manifest = [self _actionManifestForPackageSet:packageSet];
        LRActionVersion *version = [[LRActionVersion alloc] initWithType:_actionType manifest:manifest packageSet:packageSet];
        [versions addObject:version];
    }
    return versions;
}

- (NSArray *)_computeAvailableVersionSpecs {
    NSMutableArray *specs = [NSMutableArray new];
    NSMutableSet *set = [NSMutableSet new];

    for (LRActionVersion *version in _versions) {
        [self _enumerateVersionSpecsForVersion:version block:^(LRVersionSpec *versionSpec) {
            if (![set containsObject:versionSpec]) {
                [set addObject:versionSpec];
                [specs addObject:versionSpec];
            }
        }];
    }

    [specs addObject:[LRVersionSpec stableVersionSpecMatchingAnyVersionInVersionSpace:_actionType.primaryVersionSpace]];

    return specs;
}

- (void)_enumerateVersionSpecsForVersion:(LRActionVersion *)actionVersion block:(void(^)(LRVersionSpec *versionSpec))block {
    LRVersion *primaryVersion = actionVersion.primaryVersion;
    block([LRVersionSpec stableVersionSpecWithMajorFromVersion:primaryVersion]);
    block([LRVersionSpec versionSpecMatchingMajorMinorFromVersion:primaryVersion]);
    block([LRVersionSpec versionSpecMatchingVersion:primaryVersion]);
}

- (LRActionManifest *)_actionManifestForPackageSet:(LRPackageSet *)packageSet {
    NSMutableArray *layers = [NSMutableArray new];
    for (LRManifestLayer *layer in _actionType.manifestLayers) {
        if ([packageSet matchesAllPackageReferencesInArray:layer.packageReferences]) {
            [layers addObject:layer];
        }
    }
    return [[LRActionManifest alloc] initWithLayers:layers];
}

- (Action *)newInstanceWithMemento:(NSDictionary *)memento {
    return [[_actionType.actionClass alloc] initWithContextActionType:self memento:memento];
}

@end
