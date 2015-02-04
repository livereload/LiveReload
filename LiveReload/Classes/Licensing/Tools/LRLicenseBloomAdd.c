#include <stdio.h>
#include <stdlib.h>
#include <assert.h>
#include <string.h>
#include <libgen.h>

#include "licensing_config.h"
#include "licensing_core.h"
#include "bloom.h"
#include "hex.h"


int main(int argc, const char * argv[]) {
    size_t bloom_bits, bloom_hashes;
    bloom_suggest(LRLicensingBloomFilterCapacity, LRLicensingBloomFilterErrorRate, &bloom_bits, &bloom_hashes);
    bloom_data_t *bloom_data = bloom_alloc(bloom_bits);

    if (argc < 2) {
        char *path = strdup(argv[0]);
        fprintf(stderr, "Usage: %s <output.bloom> [<input1> <input2>]...\n", basename(path));
        free(path);
        exit(1);
    }
    
    char code[kLicenseCodeBufLen];
    char hashable[kLicenseCodeBufLen];
    size_t count = 0;
    
    for (int argi = 2; argi < argc; ++argi) {
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
            bloom_add(bloom_bits, bloom_hashes, bloom_data, hashable, strlen(hashable));
            ++count;
            
            if (count % 10 == 0) {
                fprintf(stderr, "Done %lu\n", (unsigned long)count);
            }
        }
    }
    
    const char *output_path = argv[1];
    FILE *output = fopen(output_path, "w");
    if (!bloom_write(output, bloom_bits, bloom_hashes, bloom_data)) {
        fprintf(stderr, "Failed to write bloom filter to file.\n");
        fclose(output);
        exit(1);
    }
    fclose(output);
    
    free(bloom_data);
    
    fprintf(stderr, "Bloom filter saved with %lu entries.\n", (unsigned long)count);
    
    return 0;
}
