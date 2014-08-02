@import LRCommons;

#import "LROutputMappingOption.h"
#import "LROutputFileMapping.h"
#import "LiveReload-Swift-x.h"
#import "Project.h"


@interface LROutputMappingOption ()

@end


@implementation LROutputMappingOption

//- (void)

- (void)loadManifest {
//    [self bind:@"availableSubfolders" toObject:self.rule.project withKeyPath:@"availableSubfolders" options:nil];
    [self observeProperties:@[@"subfolder", @"recursive", @"mask"] withSelector:@selector(presentedValueDidChange)];
}

//- (id)defaultValue {
//    return self.rule;
//}
//
//- (id)modelValue {
//    return self.rule.primaryVersionSpec;
//}
//
//- (void)setModelValue:(id)modelValue {
//    self.rule.primaryVersionSpec = modelValue;
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
    return ((Project *)self.rule.project).availableSubfolders;
}

@end
