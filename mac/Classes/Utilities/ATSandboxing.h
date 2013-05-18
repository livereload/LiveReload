
#import <Foundation/Foundation.h>

NSString *ATRealHomeDirectory();

NSString *ATUserScriptsDirectory();

BOOL ATIsSandboxed();
BOOL ATAreSecurityScopedBookmarksSupported();
BOOL ATIsUserScriptsFolderSupported();

////////////////////////////////////////////////////////////////////////////////

NSString *ATOSVersionString();
int ATVersionMake(int major, int minor, int revision);
int ATOSVersion();
BOOL ATOSVersionAtLeast(int major, int minor, int revision);
BOOL ATOSVersionLessThan(int major, int minor, int revision);

////////////////////////////////////////////////////////////////////////////////

enum {
    ATSecurityScopedURLOptionsReadWrite = 0,
    ATSecurityScopedURLOptionsReadOnly = 1 << 0,
};
typedef NSUInteger ATSecurityScopedURLOptions;

NSURL *ATInitOrResolveSecurityScopedURL(NSMutableDictionary *memento, NSURL *newURL, ATSecurityScopedURLOptions options);

////////////////////////////////////////////////////////////////////////////////

@interface NSString (ATSandboxing)

- (NSString *)stringByAbbreviatingTildeInPathUsingRealHomeDirectory;
- (NSString *)stringByExpandingTildeInPathUsingRealHomeDirectory;

@end
