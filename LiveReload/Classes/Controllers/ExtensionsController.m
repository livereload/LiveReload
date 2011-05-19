
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

- (VersionNumber)versionOfFileAtPath:(NSString *)filePath usingHashToVersionMapping:(NSString *)mappingFileName {
    NSDictionary *hashToVersion = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:mappingFileName ofType:@"plist"]];
    NSString *md5 = MD5OfFile(filePath);
    NSNumber *version = [hashToVersion objectForKey:md5];
    return (version ? [version integerValue] : VersionNumberFuture);
}


#pragma mark -
#pragma mark Safari extension

- (NSString *)bundledSafariExtensionPath {
    NSString *path = [[NSBundle mainBundle] pathForResource:@"LiveReload.safariextz" ofType:nil];
    NSAssert(path != nil, @"Cannot find LiveReload.safariextz");
    return path;
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
    [[NSWorkspace sharedWorkspace] openFile:[self bundledSafariExtensionPath] withApplication:@"Safari"];
}


#pragma mark -
#pragma mark Chrome extension

- (NSString *)bundledChromeExtensionInstallHtmlPath {
    NSString *path = [[NSBundle mainBundle] pathForResource:@"ChromeExtInstall.html" ofType:nil];
    NSAssert(path != nil, @"Cannot find ChromeExtInstall.html");
    return path;
}

- (VersionNumber)latestChromeExtensionVersion {
    if (latestChromeExtensionVersion == 0) {
        latestChromeExtensionVersion = 10600;
        NSAssert(latestChromeExtensionVersion != VersionNumberFuture, @"Cannot determine version number of the bundled Chrome extension");
    }
    return latestChromeExtensionVersion;
}

- (VersionNumber)versionOfInstalledChromeExtension {
    NSArray *libraries = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    if ([libraries count] == 0) {
        NSLog(@"versionOfInstalledChromeExtension: '~/Library/Application Support' not found");
        return 0;
    }

    NSString *library = [libraries objectAtIndex:0];
    NSString *chromeExtensions = [library stringByAppendingPathComponent:@"Google/Chrome/Default/Extensions"];
    NSFileManager *fm = [NSFileManager defaultManager];
    if (![fm fileExistsAtPath:chromeExtensions]) {
        NSLog(@"versionOfInstalledChromeExtension: %@ not found", chromeExtensions);
        return 0;
    }

    NSString *extensionDir = [chromeExtensions stringByAppendingPathComponent:@"jnihajbhpnppcggbcgedagnkighmdlei"];
    if (![fm fileExistsAtPath:chromeExtensions]) {
        NSLog(@"versionOfInstalledChromeExtension: LiveReload extension folder %@ does not exist", extensionDir);
        return 0;
    }

    VersionNumber maxVersion = 0;
    NSPredicate *mask = [NSPredicate predicateWithFormat:@"self MATCHES %@", @"[\\d.]+(_.*)?"];
    for (NSString *fileName in [fm contentsOfDirectoryAtPath:extensionDir error:nil]) {
        NSString *filePath = [extensionDir stringByAppendingPathComponent:fileName];
        if ([mask evaluateWithObject:fileName]) {
            if ([fileName rangeOfString:@"_"].length > 0) {
                fileName = [fileName substringToIndex:[fileName rangeOfString:@"_"].location];
            }

            VersionNumber version = VersionNumberFromNSString(fileName);
            NSLog(@"versionOfInstalledChromeExtension: found version %d at %@", (int)version, filePath);
            if (version > maxVersion) {
                maxVersion = version;
            }
        } else {
            NSLog(@"versionOfInstalledChromeExtension: ignoring %@ because of unexpected name", filePath);
        }
    }

    return maxVersion;
}

- (IBAction)installChromeExtension:(id)sender {
    [[NSWorkspace sharedWorkspace] openFile:[self bundledChromeExtensionInstallHtmlPath] withApplication:@"Google Chrome"];
}

@end
