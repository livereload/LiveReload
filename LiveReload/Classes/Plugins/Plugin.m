
#import "Plugin.h"
#import "Compiler.h"


@implementation Plugin

@synthesize path=_path;
@synthesize compilers=_compilers;

- (id)initWithPath:(NSString *)path {
    self = [super init];
    if (self) {
        _path = [path copy];

        NSString *plist = [path stringByAppendingPathComponent:@"Info.plist"];
        _info = [[NSDictionary dictionaryWithContentsOfFile:plist] copy];

        NSMutableArray *compilers = [NSMutableArray array];
        for (NSDictionary *compilerInfo in [_info objectForKey:@"LRCompilers"]) {
            [compilers addObject:[[[Compiler alloc] initWithDictionary:compilerInfo plugin:self] autorelease]];
        }
        _compilers = [compilers copy];
    }

    return self;
}

- (void)dealloc {
    [_path release], _path = nil;
    [_info release], _info = nil;
    [_compilers release], _compilers = nil;
    [super dealloc];
}

@end
