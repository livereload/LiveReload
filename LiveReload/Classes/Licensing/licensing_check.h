#ifndef __LiveReload__licensing_check__
#define __LiveReload__licensing_check__

#include "licensing_core.h"

typedef enum {
    LicenseCheckResultValid,
    LicenseCheckResultInvalidButWellFormed,
    LicenseCheckResultInvalid,
} LicenseCheckResult;

LicenseCheckResult licensing_check(const char *input, LicenseVersion *version, LicenseType *type);
bool licensing_is_well_formed(const char *input, LicenseVersion *version, LicenseType *type);

#endif /* defined(__LiveReload__licensing_check__) */
