
#import "OldFSTreeFilter.h"


@implementation FSTreeFilter

@synthesize enabledExtensions=_enabledExtensions;
@synthesize excludedNames=_excludedNames;
@synthesize excludedPaths=_excludedPaths;
@synthesize ignoreHiddenFiles=_ignoreHiddenFiles;

- (id)init {
    self = [super init];
    if (self) {
        _ignoreEmacsCraft = ![[NSUserDefaults standardUserDefaults] boolForKey:@"DontIgnoreEmacsTempFiles"];
    }
    return self;
}

- (void)dealloc {
    [_enabledExtensions release], _enabledExtensions = nil;
    [_excludedNames release], _excludedNames = nil;
    [super dealloc];
}


#pragma mark - Filtering

- (BOOL)acceptsFileName:(NSString *)name isDirectory:(BOOL)isDirectory {
    if (_ignoreHiddenFiles && [[name substringToIndex:1] isEqualToString:@"."]) {
        return NO;
    }

    if (_ignoreEmacsCraft) {
        if ([[name substringToIndex:1] isEqualToString:@"#"]) {
            return NO;
        }
        if ([[name substringFromIndex:[name length]-1] isEqualToString:@"~"]) {
            return NO;
        }
    }

    if (_enabledExtensions && !isDirectory) {
        NSString *extension = [name pathExtension];
        if (![_enabledExtensions containsObject:extension]) {
            return NO;
        }
    }
    if ([_excludedNames containsObject:name]) {
        return NO;
    }
    return YES;
}

- (BOOL)acceptsFile:(NSString *)relativePath isDirectory:(BOOL)isDirectory {
    if ([_excludedPaths containsObject:relativePath])
        return NO;
    return YES;
}

@end
