
#import <CommonCrypto/CommonDigest.h>
#import <CommonCrypto/CommonHMAC.h>

#import "LicenseManager.h"
#import "MASReceipt.h"
#include "licensing_core.h"
#include "licensing_check.h"
#include "hex.h"


NSString *const LicenseManagerStatusDidChangeNotification = @"LicenseManagerStatusDidChangeNotification";


void LicenseManagerStartup() {
    MASReceiptStartup();
}

BOOL LicenseManagerShouldDisplayLicensingUI() {
#ifdef APPSTORE
    return NO;
#else
    return YES;
#endif
}

BOOL LicenseManagerShouldDisplayLicenseCodeUI() {
    return LicenseManagerShouldDisplayLicensingUI() && !MASReceiptIsAuthenticated();
}

BOOL LicenseManagerIsLicenseCodeAccepted(LicenseManagerCodeStatus status) {
    switch (status) {
        case LicenseManagerCodeStatusAcceptedIndividual:
        case LicenseManagerCodeStatusAcceptedBusiness:
        case LicenseManagerCodeStatusAcceptedBusinessUnlimited:
        case LicenseManagerCodeStatusAcceptedUnknown:
            return YES;
        default:
            return NO;
    }
}

    BOOL LicenseManagerIsTrialMode() {
    return LicenseManagerShouldDisplayLicensingUI() && !MASReceiptIsAuthenticated() && !LicenseManagerIsLicenseCodeAccepted(LicenseManagerGetCodeStatus());
}

BOOL LicenseManagerShouldDisplayPurchasingUI() {
    return LicenseManagerIsTrialMode();
}

static NSString *LicenseManagerCleanLicenseCode(NSString *licenseCode) {
    if (!licenseCode)
        return @"";
    
    char buf[kLicenseCodeBufLen];
    if (licensing_reformat(buf, [licenseCode UTF8String])) {
        return [NSString stringWithUTF8String:buf];
    } else {
        return licenseCode;
    }
}

NSString *LicenseManagerGetLicenseCode() {
    return LicenseManagerCleanLicenseCode([[NSUserDefaults standardUserDefaults] stringForKey:LicenseManagerLicenseCodePreferencesKey]);
}

void LicenseManagerSetLicenseCode(NSString *licenseCode) {
    [[NSUserDefaults standardUserDefaults] setObject:LicenseManagerCleanLicenseCode(licenseCode) forKey:LicenseManagerLicenseCodePreferencesKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [[NSNotificationCenter defaultCenter] postNotificationName:LicenseManagerStatusDidChangeNotification object:nil];
}

LicenseManagerCodeStatus LicenseManagerGetCodeStatus() {
    if (!LicenseManagerShouldDisplayLicensingUI())
        return LicenseManagerCodeStatusNotRequired;
    if (MASReceiptIsAuthenticated())
        return LicenseManagerCodeStatusNotRequired;

    NSString *code = LicenseManagerGetLicenseCode();
    if (code.length == 0)
        return LicenseManagerCodeStatusNotEntered;
    
    LicenseVersion version;
    LicenseType type;
    LicenseCheckResult result = licensing_check([code UTF8String], &version, &type);
    if (result == LicenseCheckResultValid) {
        if (type == LicenseTypeIndividual) {
            return LicenseManagerCodeStatusAcceptedIndividual;
        } else if (type == LicenseTypeBusiness) {
            return LicenseManagerCodeStatusAcceptedBusiness;
        } else if (type == LicenseTypeBusinessUnlimited) {
            return LicenseManagerCodeStatusAcceptedBusinessUnlimited;
        } else {
            abort();
        }
    } else if (result == LicenseCheckResultInvalid) {
        return LicenseManagerCodeStatusIncorrectFormat;
    } else if (result == LicenseCheckResultInvalidButWellFormed) {
        return LicenseManagerCodeStatusUpdateRequired;
    } else {
        abort();
    }
}
