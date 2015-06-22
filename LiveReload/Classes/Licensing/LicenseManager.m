#import "LicenseManager.h"

#if defined(LRLegacy)
#define LICENSING_ENABLED 0
#else
#define LICENSING_ENABLED 1
#endif

#if LICENSING_ENABLED
#import <CommonCrypto/CommonDigest.h>
#import <CommonCrypto/CommonHMAC.h>

#import "MASReceipt.h"
#include "licensing_core.h"
#include "licensing_check.h"
#include "hex.h"
#endif



NSString *const LicenseManagerStatusDidChangeNotification = @"LicenseManagerStatusDidChangeNotification";


#if LICENSING_ENABLED
static LicenseManagerCodeStatus _status;
static LicenseType _type;
static LicenseVersion _version;
static BOOL _validating;
static BOOL _validationRequested;


static void LicenseManagerRevalidateCode();
static LicenseManagerCodeStatus LicenseManagerValidateCodeSync(NSString *code);
#endif

void LicenseManagerStartup() {
#if LICENSING_ENABLED
    MASReceiptStartup();
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        LicenseManagerRevalidateCode();
    });
#endif
}

BOOL LicenseManagerShouldDisplayLicensingUI() {
#ifdef APPSTORE
    return NO;
#else
    return YES;
#endif
}

BOOL LicenseManagerShouldDisplayLicenseCodeUI() {
#if LICENSING_ENABLED
    return LicenseManagerShouldDisplayLicensingUI() && !MASReceiptIsAuthenticated();
#else
    return NO;
#endif
}

BOOL LicenseManagerIsLicenseCodeAccepted(LicenseManagerCodeStatus status) {
#if LICENSING_ENABLED
    switch (status) {
        case LicenseManagerCodeStatusAcceptedIndividual:
        case LicenseManagerCodeStatusAcceptedBusiness:
        case LicenseManagerCodeStatusAcceptedBusinessUnlimited:
        case LicenseManagerCodeStatusAcceptedUnknown:
            return YES;
        default:
            return NO;
    }
#else
    return NO;
#endif
}

BOOL LicenseManagerIsTrialMode() {
#if LICENSING_ENABLED
    return LicenseManagerShouldDisplayLicensingUI() && !MASReceiptIsAuthenticated() && !LicenseManagerIsLicenseCodeAccepted(LicenseManagerGetCodeStatus());
#else
    return NO;
#endif
}

BOOL LicenseManagerShouldDisplayPurchasingUI() {
    return LicenseManagerIsTrialMode();
}

#if LICENSING_ENABLED
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
#endif

NSString *LicenseManagerGetLicenseCode() {
#if LICENSING_ENABLED
    return LicenseManagerCleanLicenseCode([[NSUserDefaults standardUserDefaults] stringForKey:LicenseManagerLicenseCodePreferencesKey]);
#else
    return @"";
#endif
}

void LicenseManagerSetLicenseCode(NSString *licenseCode) {
#if LICENSING_ENABLED
    [[NSUserDefaults standardUserDefaults] setObject:LicenseManagerCleanLicenseCode(licenseCode) forKey:LicenseManagerLicenseCodePreferencesKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    LicenseManagerRevalidateCode();
#endif
}

LicenseManagerCodeStatus LicenseManagerGetCodeStatus() {
#if LICENSING_ENABLED
    return _status;
#else
    return LicenseManagerCodeStatusLegacyVersionPerpetualLicense;
#endif
}

#if LICENSING_ENABLED
static void LicenseManagerRevalidateCode() {
    if (_validationRequested) {
        return;
    }
    if (_validating) {
        _validationRequested = YES;
        return;
    }
    
    NSString *code = LicenseManagerGetLicenseCode();
    
    _validating = YES;
    
    if (licensing_is_well_formed([code UTF8String], NULL, NULL)) {
        _status = LicenseManagerCodeStatusValidating;
        [[NSNotificationCenter defaultCenter] postNotificationName:LicenseManagerStatusDidChangeNotification object:nil];
    }

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        LicenseManagerCodeStatus status = LicenseManagerValidateCodeSync(code);
        dispatch_async(dispatch_get_main_queue(), ^{
            _validating = NO;
            _status = status;
            
            if (_validationRequested) {
                _validationRequested = NO;
                LicenseManagerRevalidateCode();
            } else {
                [[NSNotificationCenter defaultCenter] postNotificationName:LicenseManagerStatusDidChangeNotification object:nil];
            }
        });
    });
}

static LicenseManagerCodeStatus LicenseManagerValidateCodeSync(NSString *code) {
    if (!LicenseManagerShouldDisplayLicensingUI())
        return LicenseManagerCodeStatusNotRequired;
    if (MASReceiptIsAuthenticated())
        return LicenseManagerCodeStatusNotRequired;

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
#endif
