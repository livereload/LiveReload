
#import "LROutputFileMapping.h"


@interface LROutputFileMapping ()

@end


@implementation LROutputFileMapping

- (instancetype)initWithSubfolder:(NSString *)subfolder recursive:(BOOL)recursive mask:(NSString *)mask {
    self = [super init];
    if (self) {
        _subfolder = [subfolder copy];
        _recursive = recursive;
        _mask = [mask copy];
    }
    return self;
}

@end
