#include "hex.h"

void bytes_to_hex(const uint8_t *data, size_t len, char *hex) {
    static const char *HEX = "0123456789ABCDEF";
    for (size_t i = 0; i < len; i++) {
        uint8_t b = data[i];
        *hex++ = HEX[b >> 4];
        *hex++ = HEX[b & 0xF];
    }
    *hex = 0;
}
