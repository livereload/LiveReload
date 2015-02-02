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
    if (argc != 4) {
        char *path = strdup(argv[0]);
        fprintf(stderr, "Usage: %s <version> <type> <tries>\n", basename(path));
        free(path);
        exit(1);
    }
    
    LicenseVersion version = (LicenseVersion) argv[1][0];
    LicenseType type = (LicenseType) argv[2][0];
    unsigned long count = strtoul(argv[3], NULL, 10);

    size_t bloom_bits = LicensingBloomFilter_bits;
    size_t bloom_hashes = LicensingBloomFilter_hashes;
    const bloom_data_t *bloom_data = LicensingBloomFilter_data;
    
    char code[kLicenseCodeBufLen];
    char hashable[kLicenseCodeBufLen];
    bool passed = true;
    
    for (size_t i = 0; i < count; ++i) {
        licensing_generate(code, version, type);

        bool ok = licensing_reformat_without_dashes(hashable, code);
        assert(ok);
            
        ok = bloom_check(bloom_bits, bloom_hashes, bloom_data, hashable, strlen(hashable));
        if (ok) {
            printf("!!! COLLISION: %s\n", code);
            passed = false;
        }
        
        if ((i+1) % 10 == 0) {
            fprintf(stderr, "Done %lu\n", (unsigned long)(i+1));
        }
    }

    return (passed ? 0 : 1);
}
