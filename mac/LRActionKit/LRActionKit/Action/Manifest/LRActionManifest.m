@import LRCommons;

#import "LRActionManifest.h"
#import "LRManifestLayer.h"
#import "LRChildErrorSink.h"
#import "ActionKitSingleton.h"
#import "LRActionKit-Swift.h"


@interface LRActionManifest ()

@end


@implementation LRActionManifest

- (instancetype)initWithLayers:(NSArray *)layers {
    if (self = [super initWithManifest:nil errorSink:nil]) {
        _layers = [layers copy];
        [self initializeActionManifest];
    }
    return self;
}

- (void)initializeActionManifest {
    _errorSpecs = [self simpleArrayForKey:@"errors" mappedUsingBlock:^id(id obj, LRManifestLayer *layer) {
        return obj; // TODO
    }];
    _warningSpecs = [self simpleArrayForKey:@"warnings" mappedUsingBlock:^id(id obj, LRManifestLayer *layer) {
        return obj; // TODO
    }];

    _optionSpecs = [self simpleArrayForKey:@"options" mappedUsingBlock:^id(NSDictionary *spec, LRManifestLayer *layer) {
        // TODO: add context to error messages
        //
        return [[ActionKitSingleton sharedActionKit].optionRegistry parseOptionSpec:spec errorSink:[LRChildErrorSink childErrorSinkWithParentSink:layer context:[NSString stringWithFormat:@"rule %@", _identifier] uncleSink:self]];
    }];

    _commandLineSpec = [self simpleArrayForKey:@"cmdline" mappedUsingBlock:nil];

    _changeLogSummary = [self mergedValueForKey:@"changeLogSummary"];
}

- (NSArray *)simpleArrayForKey:(NSString *)key mappedUsingBlock:(id(^)(id obj, LRManifestLayer *layer))block {
    NSMutableArray *result = [NSMutableArray new];
    for (LRManifestLayer *layer in _layers) {
        NSArray *layerItems = layer.manifest[key];
        if (layerItems) {
            for (id obj in layerItems) {
                id mapped = (block ? block(obj, layer) : obj);
                if (mapped) {
                    [result addObject:mapped];
                }
            }
        }
    }
    return result;
}

- (id)mergedValueForKey:(NSString *)key {
    for (LRManifestLayer *layer in _layers) {
        id value = layer.manifest[key];
        if (value) {
            return value;
        }
    }
    return nil;
}

- (NSArray *)createOptionsWithAction:(Rule *)rule {
    return [_optionSpecs arrayByMappingElementsUsingBlock:^id(OptionSpec *optionSpec) {
        return [optionSpec newOptionWithRule:rule];
    }];
}

@end
