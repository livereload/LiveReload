
#import "ExtensionsController.h"
#import "MD5OfFile.h"
#import "VersionNumber.h"


static ExtensionsController *sharedExtensionsController;


@implementation ExtensionsController

+ (ExtensionsController *)sharedExtensionsController {
    if (sharedExtensionsController == nil) {
        sharedExtensionsController = [[ExtensionsController alloc] init];
    }
    return sharedExtensionsController;
}

- (NSString *)bundledSafariExtensionPath {
    NSString *path = [[NSBundle mainBundle] pathForResource:@"LiveReload.safariextz" ofType:nil];
    NSAssert(path != nil, @"Cannot find LiveReload.safariextz");
    return path;
}

- (NSString *)bundledChromeExtensionInstallHtmlPath {
    NSString *path = [[NSBundle mainBundle] pathForResource:@"ChromeExtInstall.html" ofType:nil];
    NSAssert(path != nil, @"Cannot find ChromeExtInstall.html");
    return path;
}

- (VersionNumber)versionOfFileAtPath:(NSString *)filePath usingHashToVersionMapping:(NSString *)mappingFileName {
    NSDictionary *hashToVersion = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:mappingFileName ofType:@"plist"]];
    NSString *md5 = MD5OfFile(filePath);
    NSNumber *version = [hashToVersion objectForKey:md5];
    return (version ? [version integerValue] : VersionNumberFuture);
}

- (VersionNumber)latestSafariExtensionVersion {
    if (latestSafariExtensionVersion == 0) {
        latestSafariExtensionVersion = [self versionOfFileAtPath:[self bundledSafariExtensionPath] usingHashToVersionMapping:@"SafariExtVersions"];
        NSAssert(latestSafariExtensionVersion != VersionNumberFuture, @"Cannot determine version number of the bundled Safari extension");
    }
    return latestSafariExtensionVersion;
}

- (VersionNumber)versionOfInstalledSafariExtension {
    NSArray *libraries = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    if ([libraries count] == 0) {
        NSLog(@"versionOfInstalledSafariExtension: ~/Library not found");
        return 0;
    }

    NSString *library = [libraries objectAtIndex:0];
    NSString *safariExtensions = [[library stringByAppendingPathComponent:@"Safari"] stringByAppendingPathComponent:@"Extensions"];
    NSFileManager *fm = [NSFileManager defaultManager];
    if (![fm fileExistsAtPath:safariExtensions]) {
        NSLog(@"versionOfInstalledSafariExtension: %@ not found", safariExtensions);
        return 0;
    }

    VersionNumber maxVersion = 0;
    for (NSString *fileName in [fm contentsOfDirectoryAtPath:safariExtensions error:nil]) {
        if ([fileName rangeOfString:@"LiveReload"].length > 0) {
            NSString *filePath = [safariExtensions stringByAppendingPathComponent:fileName];
            if ([fm fileExistsAtPath:filePath]) {
                VersionNumber version = [self versionOfFileAtPath:filePath usingHashToVersionMapping:@"SafariExtVersions"];
                NSLog(@"versionOfInstalledSafariExtension: found version %d at %@", (int)version, filePath);
                if (version > maxVersion) {
                    maxVersion = version;
                }
            } else {
                NSLog(@"versionOfInstalledSafariExtension: found %@ but it is not a file", filePath);
            }
        }
    }

    return maxVersion;
}

- (IBAction)installSafariExtension:(id)sender {
    [[NSWorkspace sharedWorkspace] openFile:[self bundledSafariExtensionPath]];
}

- (IBAction)installChromeExtension:(id)sender {
    [[NSWorkspace sharedWorkspace] openFile:[self bundledChromeExtensionInstallHtmlPath] withApplication:@"Google Chrome"];
}

@end
