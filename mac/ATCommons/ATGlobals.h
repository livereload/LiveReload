
#import <Foundation/Foundation.h>


////////////////////////////////////////////////////////////////////////////////
#pragma mark - OS versions

// 3-component decimal number: 10.7.3 -> 100703
typedef NSUInteger ATVersion;
enum { ATVersionFarFuture = 999999 }; // 99.99.99

typedef struct {
    int major;
    int minor;
    int revision;
} ATVersionComponents;

ATVersion ATVersionMake(int major, int minor, int revision);
ATVersion ATVersionFromNSString(NSString *string);

ATVersionComponents ATVersionComponentsFromVersion(ATVersion version);
NSString *NSStringFromATVersion(ATVersion version);

NSString *ATOSVersionString();
ATVersion ATOSVersion();

BOOL ATOSVersionAtLeast(int major, int minor, int revision);
BOOL ATOSVersionLessThan(int major, int minor, int revision);
BOOL ATIsOS107LionOrLater();


////////////////////////////////////////////////////////////////////////////////
#pragma mark - Sandboxing

BOOL ATIsSandboxed();
BOOL ATAreSecurityScopedBookmarksSupported();
BOOL ATIsUserScriptsFolderSupported();

NSString *ATRealHomeDirectory();

NSString *ATUserScriptsDirectory();
NSURL *ATUserScriptsDirectoryURL();

@interface NSString (ATSandboxing)

- (NSString *)stringByAbbreviatingTildeInPathUsingRealHomeDirectory;
- (NSString *)stringByExpandingTildeInPathUsingRealHomeDirectory;

@end



////////////////////////////////////////////////////////////////////////////////
#pragma mark - Security-scoped bookmarks

enum {
    ATSecurityScopedURLOptionsReadWrite = 0,
    ATSecurityScopedURLOptionsReadOnly = 1 << 0,
};
typedef NSUInteger ATSecurityScopedURLOptions;

NSURL *ATInitOrResolveSecurityScopedURL(NSMutableDictionary *memento, NSURL *newURL, ATSecurityScopedURLOptions options);
