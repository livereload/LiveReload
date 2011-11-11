
#import "CompilationOptions.h"
#import "FileCompilationOptions.h"
#import "Compiler.h"
#import "CompilerVersion.h"

#import "Bag.h"
#import "ATFunctionalStyle.h"


@implementation CompilationOptions

@synthesize compiler=_compiler;
@synthesize version=_version;
@synthesize globalOptions=_globalOptions;
@synthesize additionalArguments=_additionalArguments;


#pragma mark init/dealloc

- (id)initWithCompiler:(Compiler *)compiler memento:(NSDictionary *)memento {
    self = [super init];
    if (self) {
        _compiler = [compiler retain];
        _globalOptions = [[Bag alloc] init];
        _fileOptions = [[NSMutableDictionary alloc] init];

        id raw = [memento objectForKey:@"global"];
        if (raw) {
            [_globalOptions addEntriesFromDictionary:raw];
        }

        raw = [memento objectForKey:@"files"];
        if (raw) {
            [raw enumerateKeysAndObjectsUsingBlock:^(id filePath, id fileMemento, BOOL *stop) {
                [_fileOptions setObject:[[[FileCompilationOptions alloc] initWithFile:filePath memento:fileMemento] autorelease] forKey:filePath];
            }];
        }

        raw = [memento objectForKey:@"additionalArguments"];
        if (raw) {
            _additionalArguments = [raw copy];
        } else {
            _additionalArguments = @"";
        }
    }
    return self;
}

- (void)dealloc {
    [_compiler release], _compiler = nil;
    [_additionalArguments release], _additionalArguments = nil;
    [_globalOptions release], _globalOptions = nil;
    [_fileOptions release], _fileOptions = nil;
    [super dealloc];
}


#pragma mark - Persistence

- (NSDictionary *)memento {
    return [NSDictionary dictionaryWithObjectsAndKeys:_globalOptions.dictionary, @"global", [_fileOptions dictionaryByMappingValuesToSelector:@selector(memento)], @"files", _additionalArguments, @"additionalArguments", nil];
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

- (void)setVersion:(CompilerVersion *)version {
    if (_version != version) {
        [_version release];
        _version = [version retain];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"SomethingChanged" object:self];
    }
}


#pragma mark - Global options

- (void)setAdditionalArguments:(NSString *)additionalArguments {
    if (_additionalArguments != additionalArguments) {
        [_additionalArguments release];
        _additionalArguments = [additionalArguments retain];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"SomethingChanged" object:self];
    }
}


#pragma mark - File options

- (FileCompilationOptions *)optionsForFileAtPath:(NSString *)path create:(BOOL)create {
    FileCompilationOptions *result = [_fileOptions objectForKey:path];
    if (result == nil && create) {
        result = [[[FileCompilationOptions alloc] initWithFile:path memento:nil] autorelease];
        [_fileOptions setObject:result forKey:path];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"SomethingChanged" object:self];
    }
    return result;
}

- (NSArray *)allFileOptions {
    return [_fileOptions allValues];
}

@end
