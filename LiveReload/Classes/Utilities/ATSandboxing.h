
#import <Foundation/Foundation.h>

NSString *ATRealHomeDirectory();

NSString *ATUserScriptsDirectory();

BOOL ATIsSandboxed();
BOOL ATAreSecurityScopedBookmarksSupported();
BOOL ATIsUserScriptsFolderSupported();

#define ATIfSandboxed(yes, no) (ATIsSandboxed() ? (yes) : (no))


NSString *ATOSVersionString();
int ATVersionMake(int major, int minor, int revision);
int ATOSVersion();
BOOL ATOSVersionAtLeast(int major, int minor, int revision);
BOOL ATOSVersionLessThan(int major, int minor, int revision);
