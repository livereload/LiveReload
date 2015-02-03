#include <stdio.h>
#include <stdlib.h>
#include <assert.h>
#include <string.h>
#include <libgen.h>

#include "licensing_core.h"
#include "bloom.h"
#include "licensing_check.h"


int main(int argc, const char * argv[]) {
    if (argc < 2) {
        char *path = strdup(argv[0]);
        fprintf(stderr, "Usage: %s <input1> [<input2>]...\n", basename(path));
        free(path);
        exit(10);
    }
    
    char code[kLicenseCodeBufLen];
    bool passed = true;
    size_t count = 0;
    
    for (int argi = 1; argi < argc; ++argi) {
        const char *input_path = argv[argi];
        FILE *input = fopen(input_path, "r");
        assert(input);
        char *line;
        size_t line_len;
        while (NULL != (line = fgetln(input, &line_len))) {
            if (line_len > kLicenseCodeBufLen-1) {
                continue;
            }
            char *end = stpncpy(code, line, line_len);
            *end = 0;
            
            LicenseVersion version;
            LicenseType type;
            LicenseCheckResult result = licensing_check(code, &version, &type);
            if (result != LicenseCheckResultValid) {
                printf("!!! NOT MATCHED: %s\n", code);
                passed = false;
            }

            if (++count % 10 == 0) {
                fprintf(stderr, "Done %lu\n", (unsigned long)count);
            }
        }
    }
    
    return (passed ? 0 : 1);
}
