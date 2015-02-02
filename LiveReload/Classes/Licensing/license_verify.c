#include <stdio.h>
#include <stdlib.h>
#include <assert.h>
#include <string.h>
#include <libgen.h>

#include "licensing_core.h"
#include "bloom.h"
#include "hex.h"

#include "LicensingBloomFilter.h"


int main(int argc, const char * argv[]) {
    if (argc < 2) {
        char *path = strdup(argv[0]);
        fprintf(stderr, "Usage: %s <input1> [<input2>]...\n", basename(path));
        free(path);
        exit(10);
    }
    
    size_t bloom_bits = LicensingBloomFilter_bits;
    size_t bloom_hashes = LicensingBloomFilter_hashes;
    const bloom_data_t *bloom_data = LicensingBloomFilter_data;
    
    char code[kLicenseCodeBufLen];
    char hashable[kLicenseCodeBufLen];
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
            
            bool ok = licensing_reformat_without_dashes(hashable, code);
            assert(ok);
            ++count;
            
            ok = bloom_check(bloom_bits, bloom_hashes, bloom_data, hashable, strlen(hashable));
            if (!ok) {
                printf("!!! NOT MATCHED: %s\n", hashable);
                passed = false;
            }

            if (count % 10 == 0) {
                fprintf(stderr, "Done %lu\n", (unsigned long)count);
            }
        }
    }
    
    return (passed ? 0 : 1);
}
