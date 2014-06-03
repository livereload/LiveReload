
#import "LROutputMappingOption.h"
#import "LROutputFileMapping.h"
#import "Action.h"
#import "Project.h"
#import "ATObservation.h"


@interface LROutputMappingOption ()

@end


@implementation LROutputMappingOption

//- (void)

- (void)loadManifest {
//    [self bind:@"availableSubfolders" toObject:self.action.project withKeyPath:@"availableSubfolders" options:nil];
    [self observeProperties:@[@"subfolder", @"recursive", @"mask"] withSelector:@selector(presentedValueDidChange)];
}

//- (id)defaultValue {
//    return self.action;
//}
//
//- (id)modelValue {
//    return self.action.primaryVersionSpec;
//}
//
//- (void)setModelValue:(id)modelValue {
//    self.action.primaryVersionSpec = modelValue;
//}

- (id)presentedValue {
    return [[LROutputFileMapping alloc] initWithSubfolder:_subfolder recursive:_recursive mask:_mask];
}

- (void)setPresentedValue:(LROutputFileMapping *)presentedValue {
    _subfolder = presentedValue.subfolder;
    _recursive = presentedValue.recursive;
    _mask = presentedValue.mask;
}

- (NSArray *)availableSubfolders {
    return self.action.project.availableSubfolders;
}

@end
