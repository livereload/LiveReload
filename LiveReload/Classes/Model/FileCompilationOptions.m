
#import "FileCompilationOptions.h"


@implementation FileCompilationOptions

@synthesize enabled=_enabled;
@synthesize sourcePath=_sourcePath;
@synthesize destinationDirectory=_destinationDirectory;
@synthesize additionalOptions=_additionalOptions;


#pragma mark - init/dealloc

- (id)initWithFile:(NSString *)sourcePath memento:(NSDictionary *)memento {
    self = [super init];
    if (self) {
        _sourcePath = [sourcePath copy];
        if ([memento objectForKey:@"enabled"])
            _enabled = [[memento objectForKey:@"enabled"] boolValue];
        else
            _enabled = YES;
        _destinationDirectory = [[memento objectForKey:@"output_dir"] copy];
        if ([_destinationDirectory length] == 0) {
            _destinationDirectory = nil;
        } else if ([_destinationDirectory isEqualToString:@"."]) {
            _destinationDirectory = @"";
        }
        _additionalOptions = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void)dealloc {
    [_sourcePath release], _sourcePath = nil;
    [_destinationDirectory release], _destinationDirectory = nil;
    [_additionalOptions release], _additionalOptions = nil;
    [super dealloc];
}


#pragma mark -

- (NSDictionary *)memento {
    return [NSDictionary dictionaryWithObjectsAndKeys:(_destinationDirectory ? ([_destinationDirectory length] == 0 ? @"." : _destinationDirectory) : @""), @"output_dir", [NSNumber numberWithBool:_enabled], @"enabled", nil];
}


#pragma mark -

- (void)setEnabled:(BOOL)enabled {
    if (_enabled != enabled) {
        _enabled = enabled;
        [[NSNotificationCenter defaultCenter] postNotificationName:@"SomethingChanged" object:self];
    }
}

- (void)setDestinationDirectory:(NSString *)destinationDirectory {
    if (_destinationDirectory != destinationDirectory) {
        [_destinationDirectory release];
        _destinationDirectory = [destinationDirectory retain];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"SomethingChanged" object:self];
    }
}

- (NSString *)destinationDirectoryForDisplay {
    if (_destinationDirectory == nil)
        return @"(not set)";
    return ([_destinationDirectory length] > 0 ? _destinationDirectory : @"(root)");
}

- (void)setDestinationDirectoryForDisplay:(NSString *)destinationDirectoryForDisplay {
    destinationDirectoryForDisplay = [destinationDirectoryForDisplay stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if ([_destinationDirectory length] == 0 || [_destinationDirectory isEqualToString:@"(not set)"]) {
        self.destinationDirectory = nil;
    } else if ([destinationDirectoryForDisplay isEqualToString:@"."] || [destinationDirectoryForDisplay isEqualToString:@"(root)"]) {
        self.destinationDirectory = @"";
    } else {
        self.destinationDirectory = destinationDirectoryForDisplay;
    }
}

+ (NSSet *)keyPathsForValuesAffectingDestinationDirectoryForDisplay {
    return [NSSet setWithObject:@"destinationDirectory"];
}


#pragma mark -

+ (NSString *)commonOutputDirectoryFor:(NSArray *)fileOptions {
    NSString *commonOutputDirectory = nil;
    for (FileCompilationOptions *options in fileOptions) {
        if (options.destinationDirectory == nil)
            continue;
        if (commonOutputDirectory == nil) {
            commonOutputDirectory = options.destinationDirectory;
        } else if (![commonOutputDirectory isEqualToString:options.destinationDirectory]) {
            return nil;
        }
    }
    return (commonOutputDirectory ? commonOutputDirectory : @"__NONE_SET__");
}

@end
