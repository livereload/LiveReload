
#import "Plugin.h"
#import "Compiler.h"


@implementation Plugin

@synthesize path=_path;
@synthesize compilers=_compilers;

- (id)initWithPath:(NSString *)path {
    self = [super init];
    if (self) {
        _path = [path copy];

        NSString *plist = [path stringByAppendingPathComponent:@"manifest.json"];
        NSData *data = [NSData dataWithContentsOfFile:plist];
        if (data) {
            NSError *error;
            _info = [[NSJSONSerialization JSONObjectWithData:data options:0 error:&error] retain];
            if (!_info) {
                NSLog(@"Invalid plugin manifest %@: %@", plist, error);
            }
        }
        if (!_info) {
            _info = [[NSDictionary alloc] init];
        }

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
