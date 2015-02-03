#include "licensing_check.h"
#include "bloom.h"
#include "LicensingBloomFilter.h"
#include "hex.h"

#include <string.h>
#include <assert.h>
#include <CommonCrypto/CommonDigest.h>
#include <CommonCrypto/CommonHMAC.h>

static bool licensing_check_syntax_legacy(const char *raw, LicenseVersion *version, LicenseType *type);
static bool licensing_check_syntax(const char *raw, LicenseVersion *version, LicenseType *type);
static LicenseVersion licensing_parse_version(char ch);
static LicenseType licensing_parse_type(char ch);

LicenseCheckResult licensing_check(const char *input, LicenseVersion *version, LicenseType *type) {
    if (version) {
        *version = LicenseVersionInvalid;
    }
    if (type) {
        *type = LicenseTypeInvalid;
    }

    char raw[kLicenseCodeBufLen];
    if (!licensing_reformat_without_dashes(raw, input)) {
        return LicenseCheckResultInvalid;
    }

    size_t len = strlen(raw);
    
    if (len >= 2) {
        if (0 != strncmp(raw, "LR", kLicenseCodeProductNameLength)) {
            return LicenseCheckResultInvalid;
        }
    }
    
    if (len == kLicenseCodeLegacyTotalLength) {
        if (!licensing_check_syntax_legacy(raw, version, type)) {
            return LicenseCheckResultInvalid;
        }
    } else if (len == kLicenseCodeTotalLength) {
        if (!licensing_check_syntax(raw, version, type)) {
            return LicenseCheckResultInvalid;
        }
    } else {
        return LicenseCheckResultInvalid;
    }
    
    if (bloom_check(LicensingBloomFilter_bits, LicensingBloomFilter_hashes, LicensingBloomFilter_data, raw, len)) {
        return LicenseCheckResultValid;
    } else {
        return LicenseCheckResultInvalidButWellFormed;
    }
}

static bool licensing_check_syntax_legacy(const char *raw, LicenseVersion *version, LicenseType *type) {
    assert(strlen(raw) == kLicenseCodeLegacyTotalLength);
    
    const size_t verificator_len = 2;
    const size_t hashable_len = kLicenseCodeLegacyTotalLength - verificator_len;
    
    uint8_t verificator_raw[CC_SHA256_DIGEST_LENGTH];
    CCHmac(kCCHmacAlgSHA256, licensing_verificator_salt, strlen(licensing_verificator_salt), raw, hashable_len, verificator_raw);
    char verificator[2*CC_SHA256_DIGEST_LENGTH+1];
    bytes_to_hex(verificator_raw, CC_SHA256_DIGEST_LENGTH, verificator);
    
    if (0 == strncmp(raw + hashable_len, verificator, verificator_len)) {
        char salted[kLicenseCodeBufLen];
        strcpy(salted, raw);
        salted[hashable_len] = 0; // trim
        strcat(salted, "LiveReload");
        
        uint8_t hash_raw[CC_SHA1_DIGEST_LENGTH];
        char hash[2*CC_SHA1_DIGEST_LENGTH + 1];
        CC_SHA1(salted, (CC_LONG)strlen(salted), hash_raw);
        bytes_to_hex(hash_raw, CC_SHA1_DIGEST_LENGTH, hash);

        if (hash[1] != '9' || hash[2] != 'B' || hash[3] != 'C') {
            return false;
        }

        LicenseType t = licensing_parse_type(hash[0]);
        if (t == LicenseTypeInvalid) {
            return false;
        }
        
        if (version) {
            *version = LicenseVersion2;
        }
        if (type) {
            *type = t;
        }
        return true;
    } else {
        return false;
    }
}

static bool licensing_check_syntax(const char *raw, LicenseVersion *version, LicenseType *type) {
    assert(strlen(raw) == kLicenseCodeTotalLength);
    
    const size_t hashable_len = kLicenseCodeTotalLength - kLicenseCodeVerificatorLength;
    
    uint8_t verificator_raw[CC_SHA256_DIGEST_LENGTH];
    CCHmac(kCCHmacAlgSHA256, licensing_verificator_salt, strlen(licensing_verificator_salt), raw, hashable_len, verificator_raw);
    char verificator[2*CC_SHA256_DIGEST_LENGTH+1];
    bytes_to_hex(verificator_raw, CC_SHA256_DIGEST_LENGTH, verificator);
    
    if (0 == strncmp(raw + hashable_len, verificator, kLicenseCodeVerificatorLength)) {
        LicenseVersion v = licensing_parse_version(raw[2]);
        if (v == LicenseVersionInvalid) {
            return false;
        }

        LicenseType t = licensing_parse_type(raw[3]);
        if (t == LicenseTypeInvalid) {
            return false;
        }

        if (version) {
            *version = v;
        }
        if (type) {
            *type = t;
        }
        return true;
    } else {
        return false;
    }
}

static LicenseVersion licensing_parse_version(char ch) {
    switch (ch) {
        case (char)LicenseVersion2:
        case (char)LicenseVersion3:
            return (LicenseVersion)ch;
        default:
            return LicenseVersionInvalid;
    };
}

static LicenseType licensing_parse_type(char ch) {
    switch (ch) {
        case (char)LicenseTypeIndividual:
        case (char)LicenseTypeBusiness:
        case (char)LicenseTypeBusinessUnlimited:
            return (LicenseType)ch;
        default:
            return LicenseTypeInvalid;
    };
}
