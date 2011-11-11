
#import "RubyVersion.h"

#import "NSTask+OneLineTasksWithOutput.h"



static NSString *RubyVersionAtPath(NSString *path) {
    NSArray *components = [[[NSTask stringByLaunchingPath:path withArguments:[NSArray arrayWithObject:@"--version"] error:nil] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if ([[components objectAtIndex:0] isEqualToString:@"ruby"] && components.count > 1)
        return [components objectAtIndex:1];
    return nil;
}



@interface RubyVersion ()

- (void)validate;

@end



@interface SystemRubyVersion : RubyVersion {
    NSString              *_versionName;
    BOOL                   _valid;
}
@end



@interface RvmRubyVersion : RubyVersion {
    NSString              *_name;
    BOOL                   _valid;
}

- (id)initWithName:(NSString *)name;

@end



@implementation RubyVersion

- (void)validate {
}
- (NSString *)identifier {
    return nil;
}
- (NSString *)title {
    return nil;
}
- (NSString *)executablePath {
    return nil;
}
- (NSDictionary *)environmentModifications {
    return [NSDictionary dictionary];
}
- (BOOL)isValid {
    return YES;
}

- (NSString *)displayTitle {
    if ([self isValid])
        return [self title];
    else
        return [NSString stringWithFormat:@"%@ (missing)", [self title]];
}

+ (RubyVersion *)rubyVersionWithIdentifier:(NSString *)identifier {
    if ([identifier isEqualToString:@"system"]) {
        return [[[SystemRubyVersion alloc] init] autorelease];
    } else if ([identifier rangeOfString:@"rvm:"].location == 0) {
        return [[[RvmRubyVersion alloc] initWithName:[identifier substringFromIndex:4]] autorelease];
    } else {
        return nil;
    }
}

+ (NSArray *)availableRubyVersions {
    NSMutableArray *result = [NSMutableArray array];
    [result addObject:[[[SystemRubyVersion alloc] init] autorelease]];

    NSString *rvmRubiesFolder = [@"~/.rvm/rubies" stringByExpandingTildeInPath];
    for (NSString *name in [[NSFileManager defaultManager] contentsOfDirectoryAtPath:rvmRubiesFolder error:nil]) {
        NSString *path = [rvmRubiesFolder stringByAppendingPathComponent:name];
        BOOL isDir = NO;
        if ([[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir] && isDir) {
            RubyVersion *version = [[[RvmRubyVersion alloc] initWithName:name] autorelease];
            if (version.valid) {
                [result addObject:version];
            } else {
                NSLog(@"Found invalid RVM ruby: %@", name);
            }
        }
    }

    return [NSArray arrayWithArray:result];
}

@end



@implementation SystemRubyVersion

- (id)init {
    self = [super init];
    if (self) {
        [self validate];
    }
    return self;
}

- (void)dealloc {
    [_versionName release], _versionName = nil;
    [super dealloc];
}

- (NSString *)identifier {
    return @"system";
}

- (NSString *)executablePath {
    return @"/usr/bin/ruby";
}

- (void)validate {
    NSFileManager *fm = [NSFileManager defaultManager];
    _valid = [fm fileExistsAtPath:[self executablePath]];
}

- (BOOL)isValid {
    return _valid;
}

- (NSString *)title {
    if (_versionName == nil) {
        _versionName = [RubyVersionAtPath(self.executablePath) retain];
    }
    if (self.valid && _versionName)
        return [NSString stringWithFormat:@"System Ruby %@", _versionName];
    else
        return @"System Ruby";
}

@end



@implementation RvmRubyVersion

- (id)initWithName:(NSString *)name {
    self = [super init];
    if (self) {
        _name = [name copy];
        [self validate];
    }
    return self;
}

- (void)dealloc {
    [_name release], _name = nil;
    [super dealloc];
}

- (NSString *)identifier {
    return [NSString stringWithFormat:@"rvm:%@", _name];
}

- (NSString *)rubyHomePath {
    return [[NSString stringWithFormat:@"~/.rvm/rubies/%@", _name] stringByExpandingTildeInPath];
}

- (NSString *)executablePath {
    return [[NSString stringWithFormat:@"~/.rvm/bin/%@", _name] stringByExpandingTildeInPath];
}

- (void)validate {
    NSFileManager *fm = [NSFileManager defaultManager];
    _valid = [fm fileExistsAtPath:[self rubyHomePath]] && [fm fileExistsAtPath:[[self executablePath] stringByResolvingSymlinksInPath]];
}

- (BOOL)isValid {
    return _valid;
}

- (NSString *)title {
    return [NSString stringWithFormat:@"%@ (rvm)", _name];
}

@end
