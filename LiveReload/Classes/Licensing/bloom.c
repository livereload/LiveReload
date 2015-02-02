/*
 * Based on https://github.com/jvirkki/libbloom, provided under the following license:
 *
 *  Copyright (c) 2012, Jyri J. Virkki
 *  All rights reserved.
 *
 *  This file is under BSD license. See LICENSE file.
 *
 * Includes Murmurhash, provided under the following license:
 *
 *  All code is released to the public domain. For business purposes,
 *  Murmurhash is under the MIT license.
 */

#include "bloom.h"

#include <math.h>
#include <stdlib.h>
#include <stdio.h>


static unsigned int murmurhash2(const void * key, size_t len, const unsigned int seed);


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
    size_t hits = 0;
    register unsigned int a = murmurhash2(buffer, len, 0x9747b28c);
    register unsigned int b = murmurhash2(buffer, len, a);
    register unsigned int x;
    register unsigned int i;
    register unsigned int byte;
    register unsigned int mask;
    register unsigned char c;
    
    for (i = 0; i < hashes; i++) {
        x = (a + i*b) % bits;
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
    size_t hits = 0;
    register unsigned int a = murmurhash2(buffer, len, 0x9747b28c);
    register unsigned int b = murmurhash2(buffer, len, a);
    register unsigned int x;
    register unsigned int i;
    register unsigned int byte;
    register unsigned int mask;
    register unsigned char c;
    
    for (i = 0; i < hashes; i++) {
        x = (a + i*b) % bits;
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


//-----------------------------------------------------------------------------
// MurmurHash2, by Austin Appleby
//
// Note - This code makes a few assumptions about how your machine behaves -
//
// 1. We can read a 4-byte value from any address without crashing
// 2. sizeof(int) == 4
//
// And it has a few limitations -
//
// 1. It will not work incrementally.
// 2. It will not produce the same results on little-endian and big-endian
//    machines.
//
static unsigned int murmurhash2(const void * key, size_t len, const unsigned int seed) {
    // 'm' and 'r' are mixing constants generated offline.
    // They're not really 'magic', they just happen to work well.
    
    const unsigned int m = 0x5bd1e995;
    const int r = 24;
    
    // Initialize the hash to a 'random' value
    
    unsigned int h = seed ^ (unsigned)len;
    
    // Mix 4 bytes at a time into the hash
    
    const unsigned char * data = (const unsigned char *)key;
    
    while(len >= 4)
    {
        unsigned int k = *(unsigned int *)data;
        
        k *= m;
        k ^= k >> r;
        k *= m;
        
        h *= m;
        h ^= k;
        
        data += 4;
        len -= 4;
    }
    
    // Handle the last few bytes of the input array
    
    switch(len)
    {
        case 3: h ^= data[2] << 16;
        case 2: h ^= data[1] << 8;
        case 1: h ^= data[0];
            h *= m;
    };
    
    // Do a few final mixes of the hash to ensure the last few
    // bytes are well-incorporated.
    
    h ^= h >> 13;
    h *= m;
    h ^= h >> 15;
    
    return h;
}
