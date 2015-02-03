#include <stdio.h>
#include <stdlib.h>
#include <assert.h>
#include <string.h>
#include <libgen.h>

#include "licensing_core.h"
#include "bloom.h"
#include "hex.h"


static void bloom_print_as_c(FILE *output, const char *name, size_t bits, size_t hashes, const bloom_data_t *data);


int main(int argc, const char * argv[]) {
    const size_t limit = 100000;
    const double error_rate = 0.000001;

    if (argc < 2) {
        char *path = strdup(argv[0]);
        fprintf(stderr, "Usage: %s <output.h> [<input1> <input2>]...\n", basename(path));
        free(path);
        exit(1);
    }

    const char *output_path = argv[1];
    FILE *output;
    if (0 == strcmp(output_path, "-")) {
        output = stdout;
    } else {
        output = fopen(output_path, "w");
    }

    size_t bloom_bits, bloom_hashes;
    bloom_suggest(limit, error_rate, &bloom_bits, &bloom_hashes);
    bloom_data_t *bloom_data = bloom_alloc(bloom_bits);

    fprintf(stderr, "Bloom filter: entries = %u, bits = %u (%u KB), hashes = %u\n", (unsigned)limit, (unsigned)bloom_bits, (unsigned)(bloom_bits / 8 / 1024), (unsigned)bloom_hashes);

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
    
    bloom_print_as_c(output, "LicensingBloomFilter", bloom_bits, bloom_hashes, bloom_data);
    
    free(bloom_data);

    if (0 != strcmp(output_path, "-")) {
        fclose(output);
    }

    fprintf(stderr, "Bloom filter saved with %lu entries.\n", (unsigned long)count);

    return 0;
}


static void bloom_print_as_c(FILE *output, const char *name, size_t bits, size_t hashes, const bloom_data_t *data) {
    const size_t bytes_per_line = 16;
    
    size_t bytes = bloom_byte_size(bits);
    char hex[3];
    const char *indent = "    ";
    
    fprintf(output, "static const size_t %s_bits = %lu;\n", name, (unsigned long)bits);
    fprintf(output, "static const size_t %s_hashes = %lu;\n", name, (unsigned long)hashes);
    fprintf(output, "static const uint8_t %s_data[] = {\n", name);
    
    for (size_t i = 0; i < bytes; ++i) {
        if (i == 0) {
            fprintf(output, "%s", indent);
        } else {
            bool boundary = (i % bytes_per_line == 0);
            if (boundary) {
                fprintf(output, ",\n%s", indent);
            } else {
                fprintf(output, ", ");
            }
        }
        
        bytes_to_hex(data + i, 1, hex);
        fprintf(output, "0x%s", hex);
    }
    fprintf(output, "\n");
    
    fprintf(output, "};\n");
}

