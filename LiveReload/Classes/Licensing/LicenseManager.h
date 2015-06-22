
#import <Foundation/Foundation.h>

#define LicenseManagerLicenseCodePreferencesKey @"LicenseCode"


typedef enum {
    LicenseManagerCodeStatusNotRequired,
    LicenseManagerCodeStatusNotEntered,
    LicenseManagerCodeStatusValidating,
    LicenseManagerCodeStatusAcceptedIndividual,
    LicenseManagerCodeStatusAcceptedBusiness,
    LicenseManagerCodeStatusAcceptedBusinessUnlimited,
    LicenseManagerCodeStatusAcceptedUnknown,
    LicenseManagerCodeStatusRejected,
    LicenseManagerCodeStatusIncorrectFormat,
    LicenseManagerCodeStatusIncorrectProduct,
    LicenseManagerCodeStatusUpdateRequired,
    LicenseManagerCodeStatusLegacyVersionPerpetualLicense,
} LicenseManagerCodeStatus;


extern NSString *const LicenseManagerStatusDidChangeNotification;


void LicenseManagerStartup();

BOOL LicenseManagerShouldDisplayLicensingUI();
BOOL LicenseManagerShouldDisplayLicenseCodeUI();
BOOL LicenseManagerShouldDisplayPurchasingUI();

BOOL LicenseManagerIsTrialMode();

NSString *LicenseManagerGetLicenseCode();
void LicenseManagerSetLicenseCode(NSString *licenseCode);

LicenseManagerCodeStatus LicenseManagerGetCodeStatus();
