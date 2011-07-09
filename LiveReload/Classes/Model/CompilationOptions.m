
#import "CompilationOptions.h"
#import "FileCompilationOptions.h"
#import "Compiler.h"
#import "CompilerVersion.h"


NSString *CompilationOptionsEnabledChangedNotification = @"CompilationOptionsEnabledChangedNotification";


@implementation CompilationOptions

@synthesize compiler=_compiler;
@synthesize enabled=_enabled;
@synthesize version=_version;
@synthesize globalOptions=_globalOptions;


#pragma mark init/dealloc

- (id)initWithCompiler:(Compiler *)compiler dictionary:(NSDictionary *)info {
    self = [super init];
    if (self) {
        NSLog(@"CompilationOptions(%p) initWithCompiler:%@", self, compiler.name);
        _compiler = [compiler retain];
        _globalOptions = [[NSMutableDictionary alloc] init];
        _fileOptions = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void)dealloc {
    [_compiler release], _compiler = nil;
    [super dealloc];
}


#pragma mark - Versions

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


#pragma mark - Global options

- (void)setEnabled:(BOOL)enabled {
    if (_enabled != enabled) {
        _enabled = enabled;
        [[NSNotificationCenter defaultCenter] postNotificationName:CompilationOptionsEnabledChangedNotification object:self];
    }
}


#pragma mark - File options

- (FileCompilationOptions *)optionsForFileAtPath:(NSString *)path create:(BOOL)create {
    FileCompilationOptions *result = [_fileOptions objectForKey:path];
    if (result == nil && create) {
        result = [[FileCompilationOptions alloc] initWithFile:path];
        [_fileOptions setObject:result forKey:path];
    }
    return result;
}


@end
