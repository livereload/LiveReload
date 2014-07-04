
#import "LicenseCodeViewController.h"
#import "LicenseManager.h"


@interface LicenseCodeViewController () <NSTextFieldDelegate>

- (void)updateAll;
- (void)updateStatus;

@end


@implementation LicenseCodeViewController {
    IBOutlet NSTextField *licenseCodeField;
    IBOutlet NSTextField *licenseStatusLabel;
    IBOutlet NSTextField *additionalStatusLabel;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:@"LicenseCodeViewController" bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}

- (void)loadView {
    [super loadView];
    [self updateAll];
}

- (void)verifyLicenseCode {
    LicenseManagerSetLicenseCode(licenseCodeField.stringValue);
    [self updateStatus];
}

- (void)controlTextDidChange:(NSNotification *)obj {
    // calling LicenseManagerSetLicenseCode causes every typed character
    // to be entered twice, presumably because of NSUserDefaults sync event
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(verifyLicenseCode) object:nil];
    [self performSelector:@selector(verifyLicenseCode) withObject:nil afterDelay:0.01];
}

- (void)controlTextDidEndEditing:(NSNotification *)obj {
//    [self updateAll];
}

- (void)updateAll {
    licenseCodeField.enabled = LicenseManagerShouldDisplayLicenseCodeUI();
    licenseCodeField.stringValue = LicenseManagerGetLicenseCode();
    [self updateStatus];
}

- (void)updateStatus {
    NSString *status1 = @"";
    NSString *status2 = @"";
    switch (LicenseManagerGetCodeStatus()) {
        case LicenseManagerCodeStatusNotRequired:
            status1 = @"✔ Licensed via the Mac App Store.";
            [[licenseCodeField cell] setPlaceholderString:@"No license code required."];
            break;
        case LicenseManagerCodeStatusNotEntered:
            break;
        case LicenseManagerCodeStatusAcceptedIndividual:
            status1 = @"✔ Individual license accepted.";
            status2 = @"Thanks for choosing LiveReload!";
            break;
        case LicenseManagerCodeStatusAcceptedBusiness:
            status1 = @"✔ Per-seat business license accepted.";
            status2 = @"Thanks for choosing LiveReload for your company!";
            break;
        case LicenseManagerCodeStatusAcceptedBusinessUnlimited:
            status1 = @"✔ Unlimited business license accepted.";
            status2 = @"Thanks for choosing LiveReload for your company!";
            break;
        case LicenseManagerCodeStatusAcceptedUnknown:
            status1 = @"✔ License accepted.";
            status2 = @"Thanks for choosing LiveReload!";
            break;
        case LicenseManagerCodeStatusRejected:
        case LicenseManagerCodeStatusIncorrectProduct:
        case LicenseManagerCodeStatusIncorrectFormat:
            status1 = @"Sorry, this code is invalid.";
            break;
        case LicenseManagerCodeStatusUpdateRequired:
            status1 = @"This code requires a newer version of LiveReload.";
            status2 = @"Please upgrade.";
            break;
        default:
            status1 = @"⨯ Unexpected error when verifying the code.";
            break;
    }
    licenseStatusLabel.stringValue = status1;
    additionalStatusLabel.stringValue = status2;
}

@end
