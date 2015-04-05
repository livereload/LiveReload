@import LRCommons;

#import "LegacyCompilationOptions.h"
#import "LRLegacyFile.h"
#import "Compiler.h"
#import "CompilerVersion.h"


@implementation LegacyCompilationOptions

@synthesize compiler=_compiler;
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
                [_fileOptions setObject:[[LRLegacyFile alloc] initWithFile:filePath memento:fileMemento] forKey:filePath];
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
        } else {
            _enabled = !_compiler.optional;
        }
    }
    return self;
}


#pragma mark - Persistence

- (NSDictionary *)memento {
    return [NSDictionary dictionaryWithObjectsAndKeys:_globalOptions, @"options", [_fileOptions dictionaryByMappingValuesToBlock:^id(id key, id value) {
        return [value memento];
    }], @"files", _additionalArguments, @"additionalArguments", [NSNumber numberWithBool:_enabled], @"enabled", [NSNumber numberWithBool:_enabled], @"enabled2", nil];
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
