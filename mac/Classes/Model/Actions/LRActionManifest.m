
#import "LRActionManifest.h"
#import "LRManifestLayer.h"
#import "LROption+Factory.h"
#import "LRChildErrorSink.h"

#import "ATFunctionalStyle.h"


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

    _optionSpecs = [self simpleArrayForKey:@"options" mappedUsingBlock:^id(NSDictionary *spec, LRManifestLayer *layer) {
        // TODO: add context to error messages
        //
        return [LROption optionWithSpec:spec action:nil errorSink:[LRChildErrorSink childErrorSinkWithParentSink:layer context:[NSString stringWithFormat:@"action %@", _identifier] uncleSink:self]];
    }];
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

- (NSArray *)createOptionsWithAction:(Action *)action {
    return [_optionSpecs arrayByMappingElementsUsingBlock:^id(LROption *option) {
        return [option copyWithAction:action];
    }];
}

@end
