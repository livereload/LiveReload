
#import "ATSandboxing.h"

#include <unistd.h>
#include <sys/types.h>
#include <pwd.h>
#include <assert.h>

NSString *ATRealHomeDirectory() {
    struct passwd *pw = getpwuid(getuid());
    assert(pw);
    return [NSString stringWithUTF8String:pw->pw_dir];
}

BOOL ATIsSandboxed() {
    static BOOL sandboxed;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sandboxed = [NSHomeDirectory() compare:ATRealHomeDirectory() options:NSCaseInsensitiveSearch] != NSOrderedSame;
    });
    return sandboxed;
}

NSString *ATUserScriptsDirectory() {
    NSString *signingId = [[[NSBundle mainBundle] bundleIdentifier] lowercaseString];
    return [[ATRealHomeDirectory() stringByAppendingPathComponent:@"Library/Application Scripts"] stringByAppendingPathComponent:signingId];
}

BOOL ATAreSecurityScopedBookmarksSupported() {
    return ATOSVersionAtLeast(10, 7, 3);
}
BOOL ATIsUserScriptsFolderSupported() {
    return ATOSVersionAtLeast(10, 8, 0);
}


NSString *ATOSVersionString() {
    static NSString *result = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        result = [[[NSDictionary dictionaryWithContentsOfFile:@"/System/Library/CoreServices/SystemVersion.plist"] objectForKey:@"ProductVersion"] copy];
    });
    return result;
}

int ATVersionMake(int major, int minor, int revision) {
    return major * (100 * 100) + minor * 100 + revision;
}

int ATOSVersion() {
    static int result;
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
