
#import <Foundation/Foundation.h>
#import "VersionNumber.h"


@interface ExtensionsController : NSObject {
    VersionNumber latestSafariExtensionVersion;
    VersionNumber latestChromeExtensionVersion;
}

+ (ExtensionsController *)sharedExtensionsController;

@property(nonatomic, readonly) VersionNumber latestSafariExtensionVersion;
@property(nonatomic, readonly) VersionNumber versionOfInstalledSafariExtension;

@property(nonatomic, readonly) VersionNumber latestChromeExtensionVersion;
@property(nonatomic, readonly) VersionNumber versionOfInstalledChromeExtension;

- (IBAction)installSafariExtension:(id)sender;
- (IBAction)installChromeExtension:(id)sender;

@end
