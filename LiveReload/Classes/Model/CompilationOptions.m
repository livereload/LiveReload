
#import "CompilationOptions.h"
#import "Compiler.h"
#import "CompilerVersion.h"


@implementation CompilationOptions

@synthesize compiler=_compiler;
@synthesize enabled=_enabled;
@synthesize version=_version;
@synthesize globalOptions=_globalOptions;

- (id)initWithCompiler:(Compiler *)compiler dictionary:(NSDictionary *)info {
    self = [super init];
    if (self) {
        _compiler = [compiler retain];
        _globalOptions = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void)dealloc {
    [_compiler release], _compiler = nil;
    [super dealloc];
}

- (NSArray *)availableVersions {
    if (_availableVersions == nil) {
        _availableVersions = [[NSArray alloc] initWithObjects:
                              [[[CompilerVersion alloc] initWithName:@"0.9"] autorelease],
                              [[[CompilerVersion alloc] initWithName:@"1.0"] autorelease],
                              [[[CompilerVersion alloc] initWithName:@"1.1"] autorelease],
                              [[[CompilerVersion alloc] initWithName:@"1.2"] autorelease],
                              nil];
    }
    return _availableVersions;
}

- (CompilerVersion *)version {
    if (_version == nil) {
        _version = [[self.availableVersions objectAtIndex:0] retain];
    }
    return _version;
}

@end
