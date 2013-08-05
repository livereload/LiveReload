
#import "Plugin.h"
#import "Compiler.h"
#import "ATJson.h"


@implementation Plugin

@synthesize path=_path;
@synthesize compilers=_compilers;

- (id)initWithPath:(NSString *)path {
    self = [super init];
    if (self) {
        _path = [path copy];

        NSURL *plist = [NSURL fileURLWithPath:[path stringByAppendingPathComponent:@"manifest.json"]];
        NSError *error;
        _info = [NSDictionary LR_dictionaryWithContentsOfJSONFileURL:plist error:&error];
        if (!_info) {
            NSLog(@"Invalid plugin manifest %@: %@", plist.path, error.localizedDescription);
            _info = [[NSDictionary alloc] init];
        }

        NSMutableArray *compilers = [NSMutableArray array];
        for (NSDictionary *compilerInfo in [_info objectForKey:@"LRCompilers"]) {
            [compilers addObject:[[Compiler alloc] initWithDictionary:compilerInfo plugin:self]];
        }
        _compilers = [compilers copy];
    }

    return self;
}

@end
