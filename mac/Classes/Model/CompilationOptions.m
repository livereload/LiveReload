
#import "CompilationOptions.h"
#import "LRFile.h"
#import "Compiler.h"
#import "CompilerVersion.h"

#import "ATFunctionalStyle.h"


@implementation CompilationOptions

@synthesize compiler=_compiler;
@synthesize version=_version;
@synthesize additionalArguments=_additionalArguments;
@synthesize enabled=_enabled;


#pragma mark init/dealloc

- (id)initWithCompiler:(Compiler *)compiler memento:(NSDictionary *)memento {
    self = [super init];
    if (self) {
        _compiler = compiler;
        _globalOptions = [[NSMutableDictionary alloc] init];
        _fileOptions = [[NSMutableDictionary alloc] init];

        id raw = [memento objectForKey:@"options"];
        if (raw) {
            [_globalOptions setValuesForKeysWithDictionary:raw];
        }

        raw = [memento objectForKey:@"files"];
        if (raw) {
            [raw enumerateKeysAndObjectsUsingBlock:^(id filePath, id fileMemento, BOOL *stop) {
                [_fileOptions setObject:[[LRFile alloc] initWithFile:filePath memento:fileMemento] forKey:filePath];
            }];
        }

        raw = [memento objectForKey:@"additionalArguments"];
        if (raw) {
            _additionalArguments = [raw copy];
        } else {
            _additionalArguments = @"";
        }

        raw = [memento objectForKey:@"enabled2"];
        if (raw) {
            _enabled = [raw boolValue];
        } else if (!_compiler.optional) {
            _enabled = YES;
        } else if (!!(raw = [memento objectForKey:@"enabled"])) {
            _enabled = [raw boolValue];
        } else {
            _enabled = NO;
        }
    }
    return self;
}


#pragma mark - Persistence

- (NSDictionary *)memento {
    return [NSDictionary dictionaryWithObjectsAndKeys:_globalOptions, @"options", [_fileOptions dictionaryByMappingValuesToSelector:@selector(memento)], @"files", _additionalArguments, @"additionalArguments", [NSNumber numberWithBool:_enabled], @"enabled", [NSNumber numberWithBool:_enabled], @"enabled2", nil];
}


#pragma mark - Versions

- (NSArray *)availableVersions {
    if (_availableVersions == nil) {
        _availableVersions = [[NSArray alloc] initWithObjects:
                              [[CompilerVersion alloc] initWithName:@"0.9"],
                              [[CompilerVersion alloc] initWithName:@"1.0"],
                              [[CompilerVersion alloc] initWithName:@"1.1"],
                              [[CompilerVersion alloc] initWithName:@"1.2"],
                              nil];
    }
    return _availableVersions;
}

- (CompilerVersion *)version {
    if (_version == nil) {
        _version = [self.availableVersions objectAtIndex:0];
    }
    return _version;
}

- (void)setVersion:(CompilerVersion *)version {
    if (_version != version) {
        _version = version;
        [[NSNotificationCenter defaultCenter] postNotificationName:@"SomethingChanged" object:self];
    }
}


#pragma mark - Global options

- (void)setAdditionalArguments:(NSString *)additionalArguments {
    if (_additionalArguments != additionalArguments) {
        _additionalArguments = additionalArguments;
        [[NSNotificationCenter defaultCenter] postNotificationName:@"SomethingChanged" object:self];
    }
}

- (id)valueForOptionIdentifier:(NSString *)optionIdentifier {
    return [_globalOptions objectForKey:optionIdentifier];
}

- (void)setValue:(id)value forOptionIdentifier:(NSString *)optionIdentifier {
    [_globalOptions setObject:value forKey:optionIdentifier];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"SomethingChanged" object:self];
}



#pragma mark - File options

- (LRFile *)optionsForFileAtPath:(NSString *)path create:(BOOL)create {
    LRFile *result = [_fileOptions objectForKey:path];
    if (result == nil && create) {
        result = [[LRFile alloc] initWithFile:path memento:nil];
        [_fileOptions setObject:result forKey:path];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"SomethingChanged" object:self];
    }
    return result;
}

- (NSString *)sourcePathThatCompilesInto:(NSString *)outputPath {
    __block NSString *result = nil;
    [_fileOptions enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        LRFile *fileOptions = obj;
        if (fileOptions.enabled && [fileOptions.destinationPath isEqualToString:outputPath]) {
            result = key;
            *stop = YES;
        }
    }];
    return result;
}

- (NSArray *)allFileOptions {
    return [_fileOptions allValues];
}


#pragma mark - Enabled

- (void)setEnabled:(BOOL)enabled {
    if (enabled != _enabled) {
        _enabled = enabled;
        [[NSNotificationCenter defaultCenter] postNotificationName:@"SomethingChanged" object:self];
    }
}

- (BOOL)isActive {
    return _enabled;
}

@end
