
#import <Foundation/Foundation.h>

#define LicenseManagerLicenseCodePreferencesKey @"LicenseCode"
#define LicenseManagerProductCode @"LR"
#define LicenseManagerLicenseCodeLength 25
#define LicenseManagerLicenseCodeVerificatorLength 2
#define LicenseManagerLicenseCodeCatalogNameLength 4
#define LicenseManagerBundledCatalogs ":B9BC488CAEC879531F97DD930A866388AB7B6C7C:A9BC8BCFC52F5DC77E99380219584AACCB3D8A91:E9BCEC7C959A5BD302E5DE54FC1991E5CD6545D0:"


typedef enum {
    LicenseManagerCodeStatusNotRequired,
    LicenseManagerCodeStatusNotEntered,
    LicenseManagerCodeStatusAcceptedIndividual,
    LicenseManagerCodeStatusAcceptedBusiness,
    LicenseManagerCodeStatusAcceptedBusinessUnlimited,
    LicenseManagerCodeStatusAcceptedUnknown,
    LicenseManagerCodeStatusRejected,
    LicenseManagerCodeStatusIncorrectFormat,
    LicenseManagerCodeStatusIncorrectProduct,
    LicenseManagerCodeStatusUpdateRequired,
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
