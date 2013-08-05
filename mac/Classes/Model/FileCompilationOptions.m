
#import "FileCompilationOptions.h"
#import "Project.h"


@implementation FileCompilationOptions

@synthesize enabled=_enabled;
@synthesize sourcePath=_sourcePath;
@synthesize destinationDirectory=_destinationDirectory;
@synthesize additionalOptions=_additionalOptions;
@synthesize destinationNameMask=_destinationNameMask;


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

        _destinationNameMask = [[memento objectForKey:@"output_file"] copy] ?: @"";

        _additionalOptions = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void)dealloc {
    _sourcePath = nil;
    _destinationDirectory = nil;
    _destinationNameMask = nil;
    _additionalOptions = nil;
}


#pragma mark -

- (NSDictionary *)memento {
    return [NSDictionary dictionaryWithObjectsAndKeys:(_destinationDirectory ? ([_destinationDirectory length] == 0 ? @"." : _destinationDirectory) : @""), @"output_dir", _destinationNameMask, @"output_file", [NSNumber numberWithBool:_enabled], @"enabled", nil];
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
        _destinationDirectory = destinationDirectory;
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

- (NSString *)destinationNameForMask:(NSString *)destinationNameMask {
    NSString *sourceBaseName = [[_sourcePath lastPathComponent] stringByDeletingPathExtension];
    
    // handle a mask like "*.php" applied to a source file named like "foo.php.jade"
    while ([destinationNameMask pathExtension].length > 0 && [sourceBaseName pathExtension].length > 0 && [[destinationNameMask pathExtension] isEqualToString:[sourceBaseName pathExtension]]) {
        destinationNameMask = [destinationNameMask stringByDeletingPathExtension];
    }
    
    return [destinationNameMask stringByReplacingOccurrencesOfString:@"*" withString:sourceBaseName];
}

- (NSString *)destinationName {
    return [self destinationNameForMask:_destinationNameMask];
}

- (void)setDestinationName:(NSString *)destinationName {
    NSString *sourceBareName = [[_sourcePath lastPathComponent] stringByDeletingPathExtension];
    NSString *destinationNameMask;
    
    NSRange range = [destinationName rangeOfString:sourceBareName];
    if (range.location == NSNotFound) {
        destinationNameMask = destinationName;
    } else {
        // for an output file of "foo.php" and an input file of "foo.php.jade", generate "*.php", not "*" as a mask
        if ([sourceBareName pathExtension].length > 0 && [destinationName pathExtension].length > 0 && [[sourceBareName pathExtension] isEqualToString:[destinationName pathExtension]]) {
            sourceBareName = [sourceBareName stringByDeletingPathExtension];
            range = [destinationName rangeOfString:sourceBareName];;
        }

        NSString *before = [destinationName substringToIndex:range.location];
        NSString *after  = [destinationName substringFromIndex:range.location + range.length];
        destinationNameMask = [NSString stringWithFormat:@"%@*%@", before, after];
    }

    self.destinationNameMask = destinationNameMask;
}

- (void)setDestinationNameMask:(NSString *)destinationNameMask {
    if (_destinationNameMask != destinationNameMask) {
        _destinationNameMask = [destinationNameMask copy];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"SomethingChanged" object:self];
    }
}

- (NSString *)destinationPath {
    if (_destinationDirectory)
        return [_destinationDirectory stringByAppendingPathComponent:self.destinationName];
    else
        return nil;
}

- (void)setDestinationPath:(NSString *)destinationPath {
    self.destinationDirectory = [destinationPath stringByDeletingLastPathComponent];
    self.destinationName = [destinationPath lastPathComponent];
}

- (NSString *)destinationDisplayPathForMask:(NSString *)destinationNameMask {
    return [self.destinationDirectoryForDisplay stringByAppendingPathComponent:[self destinationNameForMask:destinationNameMask]];
}

- (NSString *)destinationPathForDisplay {
    return [self destinationDisplayPathForMask:_destinationNameMask];
}

- (void)setDestinationPathForDisplay:(NSString *)destinationPath {
    self.destinationDirectoryForDisplay = [destinationPath stringByDeletingLastPathComponent];
    self.destinationName = [destinationPath lastPathComponent];
}


#pragma mark -

+ (NSString *)commonOutputDirectoryFor:(NSArray *)fileOptions inProject:(Project *)project {
    NSString *commonOutputDirectory = nil;
    for (FileCompilationOptions *options in fileOptions) {
        if (!options.enabled)
            continue;
        if ([project isFileImported:options.sourcePath])
            continue;
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

+ (NSString *)commonDestinationNameMaskFor:(NSArray *)fileOptions inProject:(Project *)project {
    NSString *commonMask = nil;
    for (FileCompilationOptions *options in fileOptions) {
        if (!options.enabled)
            continue;
        if ([project isFileImported:options.sourcePath])
            continue;
        if (commonMask == nil) {
            commonMask = options.destinationNameMask;
        } else if (![commonMask isEqualToString:options.destinationNameMask]) {
            return nil;
        }
    }
    return commonMask;
}

@end
