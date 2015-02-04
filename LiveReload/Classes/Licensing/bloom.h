/*
 * Based on https://github.com/jvirkki/libbloom, provided under the following license:
 *
 *  Copyright (c) 2012, Jyri J. Virkki
 *  All rights reserved.
 *
 *  This file is under BSD license. See LICENSE file.
 */

#ifndef __LiveReload__bloom__
#define __LiveReload__bloom__

#include <stddef.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>

typedef uint8_t bloom_data_t;

void bloom_suggest(size_t entries, double error_rate, size_t *bits, size_t *hashes);
size_t bloom_byte_size(size_t bits);
bloom_data_t *bloom_alloc(size_t bits);
bool bloom_check(size_t bits, size_t hashes, const bloom_data_t *bf, const void *buffer, size_t len);
bool bloom_add(size_t bits, size_t hashes, bloom_data_t *bf, const void *buffer, size_t len);

bool bloom_write(FILE *file, size_t bits, size_t hashes, const bloom_data_t *data);
bool bloom_read(FILE *file, size_t *bits, size_t *hashes, bloom_data_t **data);

#endif /* defined(__LiveReload__bloom__) */
