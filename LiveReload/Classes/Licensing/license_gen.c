#include <stdio.h>
#include <stdlib.h>
#include <assert.h>
#include <string.h>
#include <libgen.h>

#include "licensing_core.h"

int main(int argc, const char * argv[]) {
    if (argc != 5) {
        char *path = strdup(argv[0]);
        fprintf(stderr, "Usage: %s <version> <type> <count> <file>\n", basename(path));
        free(path);
        exit(1);
    }
    
    LicenseVersion version = (LicenseVersion) argv[1][0];
    LicenseType type = (LicenseType) argv[2][0];
    unsigned long count = strtoul(argv[3], NULL, 10);

    const char *output_path = argv[4];
    FILE *output;
    if (0 == strcmp(output_path, "-")) {
        output = stdout;
    } else {
        output = fopen(output_path, "w");
    }
    
    char code[kLicenseCodeBufLen];
    for (size_t i = 0; i < count; ++i) {
        licensing_generate(code, version, type);
        fprintf(output, "%s\n", code);

        if ((i+1) % 10 == 0) {
            fprintf(stderr, "Done %lu\n", (unsigned long)(i+1));
        }
    }

    if (0 != strcmp(output_path, "-")) {
        fclose(output);
    }

    return 0;
}
