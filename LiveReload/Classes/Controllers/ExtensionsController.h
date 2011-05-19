
#import <Foundation/Foundation.h>


@interface ExtensionsController : NSObject {

}

+ (ExtensionsController *)sharedExtensionsController;

- (BOOL)isSafariExtensionInstalled;

- (IBAction)installSafariExtension:(id)sender;

@end
