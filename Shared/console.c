
#include "eventbus.h"
#include "console.h"
#include "common.h"

#include <stdio.h>
#include <stdarg.h>
#include <string.h>
#include <stdbool.h>


EVENTBUS_DEFINE_EVENT(console_message_added_event);


#define ConsoleBufSize 10000

static char buffer[ConsoleBufSize], *buffer_ptr;
#define buffer_end (buffer + ConsoleBufSize)


static const char *next_start_of_line(const char *buf, const char *end) {
    while (buf[-1] != '\n' && buf < end)
        ++buf;
    return buf;
}


static void expunge_old_lines(size_t bytes_to_free) {
    if (bytes_to_free < ConsoleBufSize / 10)
        bytes_to_free = ConsoleBufSize / 10;
    size_t used = buffer_ptr - buffer;
    if (bytes_to_free >= used) {
        buffer_ptr = buffer;
        *buffer_ptr = 0;
    } else if (bytes_to_free > 0) {
        char *remainder = (char *) next_start_of_line(buffer + bytes_to_free, buffer_ptr);

        size_t new_len = buffer_ptr - remainder;
        memmove(buffer, remainder, new_len);
        buffer_ptr = buffer + new_len;
        *buffer_ptr = 0;
    }
}


void console_init() {
    buffer_ptr = buffer;
    *buffer_ptr = 0;
//    console_put("The Personal Computer BASIC\nVersion C1.10 Copyright IBM Corp 1981\n62390 Bytes free\nOk");
    console_put("]");
}

void console_put(const char *text) {
    // if larger
    size_t required = strlen(text);
    size_t max_allowed = ConsoleBufSize - 1 /* zero byte */ - 1 /* possible additional \n */;
    if (required > max_allowed) {
        const char *end = text + required;
        text = next_start_of_line(text + required - max_allowed, end);
        required = end - text;
    }

    bool needs_linefeed = (text[required-1] != '\n');
    if (needs_linefeed)
        required += 1;

    size_t available = (buffer_end - buffer_ptr);
    if (available < required) {
        expunge_old_lines(required - available);
    }

    char *previous_ptr = buffer_ptr;
    buffer_ptr = stpcpy(buffer_ptr, text);
    if (needs_linefeed)
        buffer_ptr = stpcpy(buffer_ptr, "\n");

    eventbus_post(console_message_added_event, previous_ptr);
}

void console_printf(const char *format, ...) {
#define TempBufSize ConsoleBufSize
    static char temp_buffer[TempBufSize];

    va_list va;
    va_start(va, format);
    vsnprintf(temp_buffer, TempBufSize, format, va);
    va_end(va);
    console_put(temp_buffer);
}

void console_dump() {
    printf("\nCONSOLE:\n%s\n------\n", buffer);
}

const char *console_get() {
    return buffer;
}
