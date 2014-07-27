
#import <Cocoa/Cocoa.h>


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
#pragma mark - Floating-point comparisons

#define TIME_EPS (1e-6)
#define feq(a, b, eps) (fabs((a) - (b)) <= (eps))
#define fneq(a, b, eps) (fabs((a) - (b)) > (eps))
#define fle(a, b, eps) ((a) <= (b) + (eps))
#define flt(a, b, eps) ((a) < (b) - (eps))
#define fge(a, b, eps) ((a) >= (b) - (eps))
#define fgt(a, b, eps) ((a) > (b) + (eps))


////////////////////////////////////////////////////////////////////////////////
#pragma mark - Sandboxing

typedef enum {
    ATPathAccessibilityNotFound,
    ATPathAccessibilityInaccessible,
    ATPathAccessibilityAccessible,
} ATPathAccessibility;

BOOL ATIsSandboxed();
BOOL ATAreSecurityScopedBookmarksSupported();
BOOL ATIsUserScriptsFolderSupported();
ATPathAccessibility ATCheckPathAccessibility(NSURL *resourceURL);

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



////////////////////////////////////////////////////////////////////////////////
#pragma mark - Colors and graphics

CGContextRef NSGraphicsGetCurrentContext();

@interface NSColor (ATHexColors)

+ (NSColor *)colorWithHexValue:(unsigned)color;
+ (NSColor *)colorWithHexValue:(unsigned)color alpha:(CGFloat)alpha;
+ (NSColor *)colorWithHexValueWithAlpha:(unsigned)color;

@end



////////////////////////////////////////////////////////////////////////////////
#pragma mark - UI

@interface NSNib (ATGlobals)

- (id)instantiateWithOwner:(id)owner returnTopLevelObjectOfClass:(Class)klass;

@end
