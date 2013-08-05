
#import "Plugin.h"
#import "Compiler.h"
#import "SBJsonParser.h"


@implementation Plugin

@synthesize path=_path;
@synthesize compilers=_compilers;

- (id)initWithPath:(NSString *)path {
    self = [super init];
    if (self) {
        _path = [path copy];

        NSString *plist = [path stringByAppendingPathComponent:@"manifest.json"];
        SBJsonParser *jsonParser = [[SBJsonParser alloc] init];
        id repr = [jsonParser objectWithData:[NSData dataWithContentsOfFile:plist]];
        if (!repr) {
            NSLog(@"Invalid plugin manifest %@: %@", plist, jsonParser.error);
            _info = [[NSDictionary alloc] init];
        } else {
            _info = repr;
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
