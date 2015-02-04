#include "licensing_core.h"
#include "hex.h"

#include <CommonCrypto/CommonDigest.h>
#include <CommonCrypto/CommonHMAC.h>
#include <string.h>
#include <stdlib.h>
#include <ctype.h>
#include <stdio.h>
#include <assert.h>
#include <math.h>


const char *licensing_verificator_salt = "LiveReload";


static const char CHARSET[] = "0123456789ABCDEFGHIJKLMNPQRSTUVWXYZ";

// returns false if it ran out of buffer
static bool licensing_reformat_specific(char *output /* [kLicenseCodeBufLen] */, const char *input, bool dashes, size_t initial_group_len, size_t group_len) {
    char *pout = output, *pend = output + kLicenseCodeBufLen - 1;
    size_t next_dash_pos = initial_group_len;
    size_t characters = 0;
    
    for (; *input; ++input) {
        char ch = *input;
        if ((ch >= '0' && ch <= '9') || (ch >= 'A' && ch <= 'Z') || (ch >= 'a' && ch <= 'z')) {
            ch = toupper(ch);
            
            if (dashes && (characters == next_dash_pos)) {
                if (pout >= pend) {
                    return false;
                }
                *pout++ = '-';
                next_dash_pos += group_len;
            }
            if (pout >= pend) {
                return false;
            }
            *pout++ = ch;
            ++characters;
        }
    }
    
    *pout = 0;
    return true;
}

bool licensing_reformat_without_dashes(char *output /* [kLicenseCodeBufLen] */, const char *input) {
    return licensing_reformat_specific(output, input, false, 0, 0);
}

bool licensing_reformat(char *output /* [kLicenseCodeBufLen] */, const char *input) {
    char raw[kLicenseCodeBufLen];
    if (!licensing_reformat_without_dashes(raw, input)) {
        return false;
    }
    
    size_t len = strlen(raw);
    bool legacy;
    
    if (len == kLicenseCodeTotalLength) {
        legacy = false;
    } else if (((len >= 3 && licensing_parse_version(raw[2]) == LicenseVersionInvalid) || (len >= 4 && licensing_parse_type(raw[3]) == LicenseTypeInvalid)) && (len <= kLicenseCodeLegacyTotalLength)) {
        legacy = true;
    } else {
        legacy = false;
    }
    
    if (legacy) {
        return licensing_reformat_specific(output, raw, true, kLicenseCodeLegacyPrefixLength, kLicenseCodeDashGroupLength);
    } else {
        return licensing_reformat_specific(output, raw, true, kLicenseCodePrefixLength, kLicenseCodeDashGroupLength);
    }
}

void licensing_generate(char *output /* [kLicenseCodeBufLen] */, LicenseVersion version, LicenseType type) {
    const char *charset = CHARSET;
    const size_t charset_len = strlen(charset);
    
    char raw[kLicenseCodeBufLen], *praw = raw;  // doesn't include dashes
    
    // product code
    *praw++ = 'L';
    *praw++ = 'R';
    *praw++ = (char)version;
    *praw++ = (char)type;
    
    // core
    for (size_t core_chars = 0; core_chars < kLicenseCodeCoreLength; ++core_chars) {
        char ch = charset[arc4random_uniform((u_int32_t)charset_len)];
        *praw++ = ch;
    }
    
    // hash to produce a verificator
    *praw = 0;
    uint8_t verificator_raw[CC_SHA256_DIGEST_LENGTH];
    CCHmac(kCCHmacAlgSHA256, licensing_verificator_salt, strlen(licensing_verificator_salt), raw, praw - raw, verificator_raw);
    char verificator[2*CC_SHA256_DIGEST_LENGTH+1];
    bytes_to_hex(verificator_raw, CC_SHA256_DIGEST_LENGTH, verificator);
    
    // append verificator
    strncpy(praw, verificator, kLicenseCodeVerificatorLength);
    praw += kLicenseCodeVerificatorLength;
    *praw = 0;
    
    bool ok = licensing_reformat(output, raw);
    assert(ok);
}

LicenseVersion licensing_parse_version(char ch) {
    switch (ch) {
        case (char)LicenseVersion2:
        case (char)LicenseVersion3:
            return (LicenseVersion)ch;
        default:
            return LicenseVersionInvalid;
    };
}

LicenseType licensing_parse_type(char ch) {
    switch (ch) {
        case (char)LicenseTypeIndividual:
        case (char)LicenseTypeBusiness:
        case (char)LicenseTypeBusinessUnlimited:
            return (LicenseType)ch;
        default:
            return LicenseTypeInvalid;
    };
}
