
#import "LicenseCodeWindowController.h"
#import "LicenseCodeViewController.h"


static LicenseCodeWindowController *sharedLicenseCodeWindowController = nil;


@implementation LicenseCodeWindowController {
    IBOutlet NSView *licenseCodeViewPlaceholder;
    IBOutlet LicenseCodeViewController *licenseCodeViewController;
}

+ (LicenseCodeWindowController *)sharedLicenseCodeWindowController {
    if (sharedLicenseCodeWindowController == nil) {
        sharedLicenseCodeWindowController = [[LicenseCodeWindowController alloc] init];
    }
    return sharedLicenseCodeWindowController;
}

- (id)init {
    self = [super initWithWindowNibName:@"LicenseCodeWindowController"];
    if (self) {
    }
    return self;
}

- (void)windowDidLoad {
    [super windowDidLoad];

    licenseCodeViewController.view.autoresizingMask = licenseCodeViewPlaceholder.autoresizingMask;
    licenseCodeViewController.view.frame = licenseCodeViewPlaceholder.frame;
    [licenseCodeViewPlaceholder.superview replaceSubview:licenseCodeViewPlaceholder with:licenseCodeViewController.view];
}

@end
