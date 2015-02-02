#ifndef __LiveReload__licensing_core__
#define __LiveReload__licensing_core__

#include <stddef.h>
#include <stdbool.h>
#include <stdint.h>

enum {
    kLicenseCodeProductNameLength = 2,
    kLicenseCodeVersionLength = 1,
    kLicenseCodeTypeLength = 1,
    kLicenseCodeCoreLength = 33,
    kLicenseCodeVerificatorLength = 2,
    
    kLicenseCodePrefixLength = kLicenseCodeProductNameLength + kLicenseCodeVersionLength + kLicenseCodeTypeLength,
    kLicenseCodeVariablePartLength = kLicenseCodeCoreLength + kLicenseCodeVerificatorLength,
    kLicenseCodeTotalLength = kLicenseCodePrefixLength + kLicenseCodeVariablePartLength,
    
    kLicenseCodeLegacyPrefixLength = kLicenseCodeProductNameLength,
    kLicenseCodeLegacyVariablePartLength = 25,
    kLicenseCodeLegacyTotalLength = kLicenseCodeLegacyPrefixLength + kLicenseCodeLegacyVariablePartLength,
    kLicenseCodeLegacyDashGroupLength = 5,
    
    kLicenseCodeDashGroupLength = 5,
    kLicenseCodeVariablePartDashCount = (kLicenseCodeVariablePartLength + kLicenseCodeDashGroupLength - 1) / kLicenseCodeDashGroupLength,
    
    kLicenseCodeBufLen = 100 + kLicenseCodeTotalLength + 1 /* dash */ + kLicenseCodeVariablePartDashCount + 1 /* NULL */,
};

typedef enum {
    LicenseVersionInvalid = 0,
    LicenseVersion2 = '2',
    LicenseVersion3 = '3',
} LicenseVersion;

typedef enum {
    LicenseTypeInvalid = 0,
    LicenseTypeIndividual = 'A',
    LicenseTypeBusiness = 'B',
    LicenseTypeBusinessUnlimited = 'E',
} LicenseType;

//LicenseType licensing_check(const char *license_code);

void licensing_generate(char *output /* [kLicenseCodeBufLen] */, LicenseVersion version, LicenseType type);
bool licensing_reformat_without_dashes(char *output /* [kLicenseCodeBufLen] */, const char *input);
bool licensing_reformat(char *output /* [kLicenseCodeBufLen] */, const char *input);

#endif /* defined(__LiveReload__licensing_core__) */
