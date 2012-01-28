
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
            _info = [repr retain];
        }
        [jsonParser release];

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
