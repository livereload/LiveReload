
#import "ATGlobals.h"

#include <unistd.h>
#include <sys/types.h>
#include <pwd.h>
#include <assert.h>



////////////////////////////////////////////////////////////////////////////////
#pragma mark - OS versions

ATVersion ATVersionMake(int major, int minor, int revision) {
    return major * (100 * 100) + minor * 100 + revision;
}

ATVersion ATVersionFromNSString(NSString *string) {
    NSArray *components = [string componentsSeparatedByString:@"."];
    int major = [[components objectAtIndex:0] intValue];
    int minor = ([components count] > 1 ? [[components objectAtIndex:1] intValue] : 0);
    int revision = ([components count] > 2 ? [[components objectAtIndex:2] intValue] : 0);
    return ATVersionMake(major, minor, revision);
}

ATVersionComponents ATVersionComponentsFromVersion(ATVersion version) {
    ATVersionComponents components;
    components.revision = version % 100;
    version /= 100;
    components.minor = version % 100;
    version /= 100;
    components.major = (int)version;
    return components;
}

NSString *NSStringFromATVersion(ATVersion version) {
    ATVersionComponents components = ATVersionComponentsFromVersion(version);
    return [NSString stringWithFormat:@"%d.%d.%d", components.major, components.minor, components.revision];
}

NSString *ATOSVersionString() {
    static NSString *result = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        result = [[[NSDictionary dictionaryWithContentsOfFile:@"/System/Library/CoreServices/SystemVersion.plist"] objectForKey:@"ProductVersion"] copy];
    });
    return result;
}

ATVersion ATOSVersion() {
    static ATVersion result;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSArray *components = [[ATOSVersionString() stringByAppendingString:@".0.0.0"] componentsSeparatedByString:@"."];
        int major = [[components objectAtIndex:0] intValue];
        int minor = [[components objectAtIndex:1] intValue];
        int revision = [[components objectAtIndex:2] intValue];
        result = ATVersionMake(major, minor, revision);
    });
    return result;
}

BOOL ATOSVersionAtLeast(int major, int minor, int revision) {
    return ATOSVersion() >= ATVersionMake(major, minor, revision);
}
BOOL ATOSVersionLessThan(int major, int minor, int revision) {
    return ATOSVersion() < ATVersionMake(major, minor, revision);
}
BOOL ATIsOS107LionOrLater() {
    return ATOSVersionAtLeast(10, 7, 0);
}



////////////////////////////////////////////////////////////////////////////////
#pragma mark - Sandboxing

NSString *ATRealHomeDirectory() {
    struct passwd *pw = getpwuid(getuid());
    assert(pw);
    return [NSString stringWithUTF8String:pw->pw_dir];
}

BOOL ATIsSandboxed() {
    return [NSHomeDirectory() compare:ATRealHomeDirectory() options:NSCaseInsensitiveSearch] != NSOrderedSame;
}

NSString *ATUserScriptsDirectory() {
    NSError *error = nil;
    if (ATIsUserScriptsFolderSupported()) {
        return [[[NSFileManager defaultManager] URLForDirectory:NSApplicationScriptsDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:&error] path];
    } else {
        NSString *bundleId = [[NSBundle mainBundle] bundleIdentifier];
        return [[ATRealHomeDirectory() stringByAppendingPathComponent:@"Library/Application Scripts"] stringByAppendingPathComponent:bundleId];
    }
}

NSURL *ATUserScriptsDirectoryURL() {
    NSError *error = nil;
    if (ATIsUserScriptsFolderSupported()) {
        NSURL *url = [[NSFileManager defaultManager] URLForDirectory:NSApplicationScriptsDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:&error];
        if (url)
            return url;
    }

    NSString *bundleId = [[NSBundle mainBundle] bundleIdentifier];
    return [NSURL fileURLWithPath:[[ATRealHomeDirectory() stringByAppendingPathComponent:@"Library/Application Scripts"] stringByAppendingPathComponent:bundleId]];
}

BOOL ATAreSecurityScopedBookmarksSupported() {
    return ATOSVersionAtLeast(10, 7, 3);
}
BOOL ATIsUserScriptsFolderSupported() {
    return ATOSVersionAtLeast(10, 8, 0);
}

ATPathAccessibility ATCheckPathAccessibility(NSURL *resourceURL) {
    NSError * __autoreleasing error = nil;
    NSDictionary *values = [resourceURL resourceValuesForKeys:@[NSURLIsDirectoryKey, NSURLIsReadableKey, NSURLIsExecutableKey] error:&error];
    NSLog(@"URL = %@, values = %@, error = %@ / %ld / %@", resourceURL, values, error.domain, (long)error.code, error.localizedDescription);
    if (!values) {
        if (!([error.domain isEqualToString:NSCocoaErrorDomain] && error.code == NSFileReadNoSuchFileError)) {
            NSLog(@"Cannot read %@ because of unknown error: %@ / %ld / %@", resourceURL, error.domain, (long)error.code, error.localizedDescription);
        }
        return ATPathAccessibilityNotFound;
    }
    if (![values[NSURLIsReadableKey] boolValue]) {
        return ATPathAccessibilityInaccessible;
    }
    if ([values[NSURLIsDirectoryKey] boolValue] && ![values[NSURLIsExecutableKey] boolValue]) {
        return ATPathAccessibilityInaccessible;
    }
    return ATPathAccessibilityAccessible;
}

@implementation NSString (ATSandboxing)

- (NSString *)stringByAbbreviatingTildeInPathUsingRealHomeDirectory {
    NSString *realHome = ATRealHomeDirectory();

    NSUInteger ourLength = self.length;
    NSUInteger homeLength = realHome.length;

    if (ourLength < realHome.length)
        return self;
    if ([[self substringToIndex:homeLength] isEqualToString:realHome]) {
        if (ourLength == homeLength)
            return @"~";
        else if ([self characterAtIndex:homeLength] == '/')
            return [@"~" stringByAppendingString:[self substringFromIndex:homeLength]];
    }
    return self;
}

- (NSString *)stringByExpandingTildeInPathUsingRealHomeDirectory {
    NSString *realHome = ATRealHomeDirectory();
    if ([self length] > 0 && [self characterAtIndex:0] == '~') {
        if ([self length] == 1)
            return realHome;
        else if ([self characterAtIndex:1] == '/')
            return [realHome stringByAppendingPathComponent:[self substringFromIndex:2]];
    }
    return self;
}

@end



////////////////////////////////////////////////////////////////////////////////
#pragma mark - Security-scoped bookmarks

NSURL *ATInitOrResolveSecurityScopedURL(NSMutableDictionary *memento, NSURL *newURL, ATSecurityScopedURLOptions options) {
    NSError *error;

    if (newURL) {
        [memento setObject:[[newURL path] stringByAbbreviatingTildeInPathUsingRealHomeDirectory] forKey:@"path"];  // solely for debugging and identification purposes; we'll always use a bookmark when available

        NSURLBookmarkCreationOptions o = NSURLBookmarkCreationWithSecurityScope;
        if ((options & ATSecurityScopedURLOptionsReadOnly) == ATSecurityScopedURLOptionsReadOnly)
            o |= NSURLBookmarkCreationSecurityScopeAllowOnlyReadAccess;
        NSData *bookmarkData = [newURL bookmarkDataWithOptions:NSURLBookmarkCreationWithSecurityScope includingResourceValuesForKeys:@[NSURLPathKey] relativeToURL:nil error:&error];
        if (!bookmarkData) {
            [memento removeObjectForKey:@"bookmark"];
            NSLog(@"Failed to create a security-scoped bookmark for %@: %@", newURL, error);
        } else {
            [memento setObject:[bookmarkData base64EncodedStringWithOptions:0] forKey:@"bookmark"];
            NSLog(@"Created security-scoped bookmark for %@", newURL);
        }

        return newURL;
    } else {
        NSString *pathString = memento[@"path"];
        NSString *bookmarkString = memento[@"bookmark"];

        if (bookmarkString) {
            NSData *bookmark = [[NSData alloc] initWithBase64EncodedString:bookmarkString options:NSDataBase64DecodingIgnoreUnknownCharacters];

            BOOL stale = NO;
            NSURL *url = [NSURL URLByResolvingBookmarkData:bookmark options:NSURLBookmarkResolutionWithSecurityScope|NSURLBookmarkResolutionWithoutUI relativeToURL:nil bookmarkDataIsStale:&stale error:&error];
            if (!url) {
                NSString *bookmarkedPath = [NSURL resourceValuesForKeys:@[NSURLPathKey] fromBookmarkData:bookmark][NSURLPathKey];
                if (bookmarkedPath) {
                    NSLog(@"Failed to resolve a security-scoped bookmark for %@", bookmarkedPath);
                    return [NSURL fileURLWithPath:bookmarkedPath];
                } else {
                    NSLog(@"Failed to resolve a security-scoped bookmark for %@ (apparently the bookmark is completely invalid)", pathString);
                    return [NSURL fileURLWithPath:[pathString stringByExpandingTildeInPathUsingRealHomeDirectory]];
                }
            } else {
                if (stale) {
                    NSURLBookmarkCreationOptions o = NSURLBookmarkCreationWithSecurityScope;
                    if ((options & ATSecurityScopedURLOptionsReadOnly) == ATSecurityScopedURLOptionsReadOnly)
                        o |= NSURLBookmarkCreationSecurityScopeAllowOnlyReadAccess;
                    NSData *bookmarkData = [newURL bookmarkDataWithOptions:NSURLBookmarkCreationWithSecurityScope includingResourceValuesForKeys:@[NSURLPathKey] relativeToURL:nil error:&error];
                    if (!bookmarkData) {
                        NSLog(@"Failed to update a security-scoped bookmark for %@: %@", newURL, error);
                    } else {
                        [memento setObject:[bookmarkData base64EncodedStringWithOptions:0] forKey:@"bookmark"];
                        NSLog(@"Updated security-scoped bookmark for %@", newURL);
                    }
                }

                return url;
            }
        } else if (pathString) {
            return [NSURL fileURLWithPath:[pathString stringByExpandingTildeInPathUsingRealHomeDirectory]];
        } else {
            return nil;
        }
    }
}



////////////////////////////////////////////////////////////////////////////////
#pragma mark - Colors

CGContextRef NSGraphicsGetCurrentContext() {
    return (CGContextRef)[NSGraphicsContext currentContext].graphicsPort;
}

@implementation NSColor (ATHexColors)

+ (NSColor *)colorWithHexValue:(unsigned)color {
    return [self colorWithHexValue:color alpha:1.0];
}

+ (NSColor *)colorWithHexValueWithAlpha:(unsigned)color {
    unsigned alpha = (color >> 24) & 0xFF;
    return [self colorWithHexValue:color alpha:alpha/255.0];
}

+ (NSColor *)colorWithHexValue:(unsigned)color alpha:(CGFloat)alpha {
    unsigned blue = color & 0xFF;
    unsigned green = (color >> 8) & 0xFF;
    unsigned red = (color >> 16) & 0xFF;
    return [NSColor colorWithCalibratedRed:red/255.0 green:green/255.0 blue:blue/255.0 alpha:alpha];
}

@end



////////////////////////////////////////////////////////////////////////////////
#pragma mark - UI

@implementation NSNib (ATGlobals)

- (id)instantiateWithOwner:(id)owner returnTopLevelObjectOfClass:(Class)klass {
    NSArray *topLevelObjects = nil;
    if ([self instantiateWithOwner:owner topLevelObjects:&topLevelObjects]) {
        for (id object in topLevelObjects)
            if ([object isKindOfClass:klass])
                return object;
    }
    return nil;
}

@end
