
#import <CommonCrypto/CommonDigest.h>
#import <CommonCrypto/CommonHMAC.h>

#import "LicenseManager.h"
#import "MASReceipt.h"

#import <sys/stat.h>


NSString *const LicenseManagerStatusDidChangeNotification = @"LicenseManagerStatusDidChangeNotification";

static void bytes_to_hex(const uint8_t *data, int len, char *hex) {
    static const char *HEX = "0123456789ABCDEF";
    for (int i = 0; i < len; i++) {
        uint8_t b = data[i];
        *hex++ = HEX[b >> 4];
        *hex++ = HEX[b & 0xF];
    }
    *hex = 0;
}

static NSString *HexRepresentation(const uint8_t *data, int len) {
    char hex[2 * len + 1];
    bytes_to_hex(data, len, hex);
    return [NSString stringWithUTF8String:hex];
}


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
    NSMutableString *code = [[[[[licenseCode stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] uppercaseString] stringByReplacingOccurrencesOfString:@"-" withString:@""] mutableCopy] autorelease];
    if (code.length == LicenseManagerLicenseCodeLength + LicenseManagerProductCode.length) {
        [code insertString:@"-" atIndex:2 + 4*5];
        [code insertString:@"-" atIndex:2 + 3*5];
        [code insertString:@"-" atIndex:2 + 2*5];
        [code insertString:@"-" atIndex:2 + 1*5];
        [code insertString:@"-" atIndex:2];
    }
    return [NSString stringWithString:code];
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
    
    code = [code stringByReplacingOccurrencesOfString:@"-" withString:@""];
    if (code.length != LicenseManagerLicenseCodeLength + LicenseManagerProductCode.length)
        return LicenseManagerCodeStatusIncorrectFormat;
    
    NSString *hashablePart = [code substringToIndex:code.length - LicenseManagerLicenseCodeVerificatorLength];
    const char *hashableRaw = [hashablePart UTF8String];
    
    NSString *enteredVerificator = [code substringFromIndex:code.length - LicenseManagerLicenseCodeVerificatorLength];
    
    uint8_t verificatorRaw[CC_SHA256_DIGEST_LENGTH];
    const char *salt = "LiveReload";
    CCHmac(kCCHmacAlgSHA256, salt, strlen(salt), hashableRaw, strlen(hashableRaw), verificatorRaw);
    NSString *verificator = [HexRepresentation(verificatorRaw, CC_SHA256_DIGEST_LENGTH) substringToIndex:LicenseManagerLicenseCodeVerificatorLength];
    
    if (![enteredVerificator isEqualToString:verificator])
        return LicenseManagerCodeStatusIncorrectFormat;

    if (![[code substringToIndex:LicenseManagerProductCode.length] isEqualToString:LicenseManagerProductCode])
        return LicenseManagerCodeStatusIncorrectProduct;
    
    NSString *saltedHashable = [hashablePart stringByAppendingString:@"LiveReload"];
    const char *saltedHashableRaw = [saltedHashable UTF8String];
    
    uint8_t licenseCodeHashRaw[CC_SHA1_DIGEST_LENGTH];
    CC_SHA1(saltedHashableRaw, strlen(saltedHashableRaw), licenseCodeHashRaw);
    
    char licenseCodeHash[1 + 2 * CC_SHA1_DIGEST_LENGTH + 1 + 1];
    licenseCodeHash[0] = '\n';
    bytes_to_hex(licenseCodeHashRaw, CC_SHA1_DIGEST_LENGTH, licenseCodeHash + 1);

    char catalogRef[1 + LicenseManagerLicenseCodeCatalogNameLength + 1];
    catalogRef[0] = ':';
    strncpy(catalogRef + 1, licenseCodeHash + 1, LicenseManagerLicenseCodeCatalogNameLength);
    catalogRef[1 + LicenseManagerLicenseCodeCatalogNameLength] = 0;

    const char *correctCatalogHash = strstr(LicenseManagerBundledCatalogs, catalogRef);
    if (!correctCatalogHash)
        return LicenseManagerCodeStatusUpdateRequired;
    ++correctCatalogHash;

    const char *correctCatalogHashEnd = strchr(correctCatalogHash, ':');
    if (!correctCatalogHashEnd)
        abort();
    if (correctCatalogHashEnd - correctCatalogHash != 2 * CC_SHA1_DIGEST_LENGTH)
        abort();

    NSString *catalogFileName = [NSString stringWithFormat:@"LR-%s.public", catalogRef+1];
    NSString *catalogPath = [[NSBundle mainBundle] pathForResource:catalogFileName ofType:nil];
    if (!catalogPath)
        abort();
    
    const char *catalogPathC = [catalogPath UTF8String];
    
    struct stat st;
    int fd = open(catalogPathC, O_RDONLY);
    if (fd < 0)
        abort();
    if (fstat(fd, &st) < 0)
        abort();
    
    int catalogLen = (int) st.st_size;
    char *catalogData = (char *) malloc(catalogLen + 1);
    if (!catalogData)
        abort();
    
    if (read(fd, catalogData, catalogLen) < catalogLen)
        abort();
    if (close(fd) < 0)
        abort();
    
    catalogData[catalogLen] = 0;

    uint8_t catalogHmacRaw[CC_SHA1_DIGEST_LENGTH];
    CCHmac(kCCHmacAlgSHA1, salt, strlen(salt), catalogData, catalogLen, catalogHmacRaw);

    char catalogHash[2 * CC_SHA1_DIGEST_LENGTH + 1];
    bytes_to_hex(catalogHmacRaw, CC_SHA1_DIGEST_LENGTH, catalogHash);
    
    if (0 != strncmp(correctCatalogHash, catalogHash, 2 * CC_SHA1_DIGEST_LENGTH))
        abort();  // catalog has been tampered with
    
    licenseCodeHash[1 + 2 * CC_SHA1_DIGEST_LENGTH] = '\n';
    licenseCodeHash[1 + 2 * CC_SHA1_DIGEST_LENGTH + 1] = 0;
    
    if (!strstr(catalogData, licenseCodeHash))
        return LicenseManagerCodeStatusRejected;
    else
        switch (licenseCodeHash[1]) {
            case 'A':
                return LicenseManagerCodeStatusAcceptedIndividual;
            case 'B':
                return LicenseManagerCodeStatusAcceptedBusiness;
            case 'E':
                return LicenseManagerCodeStatusAcceptedBusinessUnlimited;
            default:
                return LicenseManagerCodeStatusAcceptedUnknown;
        }
}
