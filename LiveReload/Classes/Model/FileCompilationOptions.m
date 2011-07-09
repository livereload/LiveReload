
#import "FileCompilationOptions.h"


@implementation FileCompilationOptions

@synthesize sourcePath=_sourcePath;
@synthesize destinationDirectory=_destinationDirectory;
@synthesize additionalOptions=_additionalOptions;


#pragma mark - init/dealloc

- (id)initWithFile:(NSString *)sourcePath {
    self = [super init];
    if (self) {
        _sourcePath = [sourcePath copy];
        _destinationDirectory = nil;
        _additionalOptions = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void)dealloc {
    [_sourcePath release], _sourcePath = nil;
    [_destinationDirectory release], _destinationDirectory = nil;
    [_additionalOptions release], _additionalOptions = nil;
    [super dealloc];
}

@end
