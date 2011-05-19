
#import <Foundation/Foundation.h>
#import "VersionNumber.h"


@interface ExtensionsController : NSObject {
    VersionNumber latestSafariExtensionVersion;
}

+ (ExtensionsController *)sharedExtensionsController;

@property(nonatomic, readonly) VersionNumber latestSafariExtensionVersion;
@property(nonatomic, readonly) VersionNumber versionOfInstalledSafariExtension;

- (IBAction)installSafariExtension:(id)sender;

@end
