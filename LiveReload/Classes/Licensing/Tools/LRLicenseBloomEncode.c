#include <stdio.h>
#include <stdlib.h>
#include <assert.h>
#include <string.h>
#include <libgen.h>

#include "licensing_config.h"
#include "licensing_core.h"
#include "bloom.h"
#include "hex.h"


static void bloom_print_as_c(FILE *output, const char *name, size_t bits, size_t hashes, const bloom_data_t *data);


int main(int argc, const char * argv[]) {
    size_t bloom_bits, bloom_hashes;
    bloom_suggest(LRLicensingBloomFilterCapacity, LRLicensingBloomFilterErrorRate, &bloom_bits, &bloom_hashes);
    size_t bytes = bloom_byte_size(bloom_bits);
    bloom_data_t *bloom_data = bloom_alloc(bloom_bits);

    if (argc < 2) {
        char *path = strdup(argv[0]);
        fprintf(stderr, "Usage: %s <output.h> [<input1.bloom> <input2.bloom>]...\n", basename(path));
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

    for (int argi = 2; argi < argc; ++argi) {
        size_t bits, hashes;
        bloom_data_t *data;

        const char *input_path = argv[argi];
        FILE *input = fopen(input_path, "r");
        if (!bloom_read(input, &bits, &hashes, &data)) {
            fprintf(stderr, "Failed to read bloom filter from %s.\n", input_path);
            exit(1);
        }
        fclose(input);
        
        if (bits != bloom_bits || hashes != bloom_hashes) {
            fprintf(stderr, "Incompatible bloom filter in %s.\n", input_path);
            exit(1);
        }
        
        for (size_t i = 0; i < bytes; ++i) {
            bloom_data[i] |= data[i];
        }
        
        free(data);

        fprintf(stderr, "Imported: %s\n", input_path);
    }
    
    bloom_print_as_c(output, "LicensingBloomFilter", bloom_bits, bloom_hashes, bloom_data);
    
    free(bloom_data);

    if (0 != strcmp(output_path, "-")) {
        fclose(output);
    }

    fprintf(stderr, "Bloom filter exported.\n");

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

