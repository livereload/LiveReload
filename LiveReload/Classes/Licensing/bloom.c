/*
 * Based on https://github.com/jvirkki/libbloom, provided under the following license:
 *
 *  Copyright (c) 2012, Jyri J. Virkki
 *  All rights reserved.
 *
 *  This file is under BSD license. See LICENSE file.
 */

#include "bloom.h"

#include <math.h>
#include <stdlib.h>
#include <stdio.h>
#include <assert.h>
#include <CommonCrypto/CommonKeyDerivation.h>


static const uint8_t BloomFilterSalt[] = "LiveReloadLicensing";


void bloom_suggest(size_t entries, double error_rate, size_t *bits, size_t *hashes) {
    double num = log(error_rate);
    double denom = 0.480453013918201; // ln(2)^2
    double bpe = -(num / denom);
    *bits = (size_t)((double)entries * bpe);
    *hashes = (size_t)(double)ceil(0.693147180559945 * bpe);  // ln(2);
}

size_t bloom_byte_size(size_t bits) {
    return (bits + 7) / 8;
}

bloom_data_t *bloom_alloc(size_t bits) {
    return calloc(bloom_byte_size(bits), 1);
}

bool bloom_check(size_t bits, size_t hashes, const bloom_data_t *bf, const void *buffer, size_t len) {
    uint32_t dwords[hashes];
    int result = CCKeyDerivationPBKDF(kCCPBKDF2, buffer, len, (const uint8_t *)BloomFilterSalt, sizeof(BloomFilterSalt), kCCPRFHmacAlgSHA512, 100000, (uint8_t *)dwords, hashes * sizeof(uint32_t));
    assert(result == 0);

    size_t hits = 0;
    register unsigned int x;
    register unsigned int i;
    register unsigned int byte;
    register unsigned int mask;
    register unsigned char c;
    
    for (i = 0; i < hashes; i++) {
        x = dwords[i] % bits;
        byte = x >> 3;
        c = bf[byte];        // expensive memory access
        mask = 1 << (x % 8);
        
        if (c & mask) {
            hits++;
        }
    }
    
    return (hits == hashes);
}

bool bloom_add(size_t bits, size_t hashes, bloom_data_t *bf, const void *buffer, size_t len) {
#if 0
    int rounds = CCCalibratePBKDF(kCCPBKDF2, len, sizeof(BloomFilterSalt), kCCPRFHmacAlgSHA512, hashes * sizeof(uint32_t), 1000);
    printf("rounds = %d\n", rounds);
#endif

    uint32_t dwords[hashes];
    int result = CCKeyDerivationPBKDF(kCCPBKDF2, buffer, len, (const uint8_t *)BloomFilterSalt, sizeof(BloomFilterSalt), kCCPRFHmacAlgSHA512, 100000, (uint8_t *)dwords, hashes * sizeof(uint32_t));
    assert(result == 0);

    size_t hits = 0;
    register unsigned int x;
    register unsigned int i;
    register unsigned int byte;
    register unsigned int mask;
    register unsigned char c;
    
    for (i = 0; i < hashes; i++) {
        x = dwords[i] % bits;
        byte = x >> 3;
        c = bf[byte];        // expensive memory access
        mask = 1 << (x % 8);
        
        if (c & mask) {
            hits++;
        } else {
            bf[byte] = c | mask;
        }
    }
    return (hits == hashes);
}

bool bloom_write(FILE *file, size_t bits, size_t hashes, const bloom_data_t *data) {
    if (fwrite(&bits, sizeof(bits), 1, file) != 1) {
        return false;
    }
    if (fwrite(&hashes, sizeof(hashes), 1, file) != 1) {
        return false;
    }
    size_t bytes = bloom_byte_size(bits);
    if (fwrite(data, bytes, 1, file) != 1) {
        return false;
    }
    return true;
}

bool bloom_read(FILE *file, size_t *bits, size_t *hashes, bloom_data_t **data) {
    if (fread(bits, sizeof(*bits), 1, file) != 1) {
        return false;
    }
    if (fread(hashes, sizeof(*hashes), 1, file) != 1) {
        return false;
    }

    *data = bloom_alloc(*bits);
    size_t bytes = bloom_byte_size(*bits);
    if (fread(*data, bytes, 1, file) != 1) {
        free(*data);
        *data = NULL;
        return false;
    }
    return true;
}
