
#include "stringutil.h"
#include "autorelease.h"
#include "osdep.h"

#include <string.h>
#include <stdlib.h>


char *str_replace(const char *string, const char *what, const char *replacement) {
    const char *next;
    int what_len = strlen(what);

    int occurrences = 0;
    for (const char *start = string; (next = strstr(start, what)) != NULL;) {
        ++occurrences;
        start = next + what_len;
    }

    int len = strlen(string) + occurrences * (strlen(replacement) - what_len);
    char *result = (char *) malloc(len + 1);
    *result = 0;

    const char *start = string;
    while ((next = strstr(start, what)) != NULL) {
        strncat(result, start, next - start);
        strcat(result, replacement);
        start = next + what_len;
    }
    strcat(result, start);

    return AU(result);
}


const char *str_collapse_paths(const char *text_with_paths, const char *current_project_path) {
    // order is important here! LiveReload could be inside $HOME
    text_with_paths = str_replace(text_with_paths, os_bundled_resources_path(), "$LiveReloadResources");

    const char *home = getenv("HOME");
    if (home) {
        text_with_paths = str_replace(text_with_paths, home, "~");
        if (current_project_path) {
            current_project_path = str_replace(current_project_path, home, "~");
        }
    }

    if (current_project_path) {
        text_with_paths = str_replace(text_with_paths, current_project_path, ".");
    }

    return text_with_paths;
}

bool str_starts_with(const char *string, const char *suffix) {
    int len = strlen(string), suflen = strlen(suffix);
    return len >= suflen && 0 == strncmp(string, suffix, suflen);
}

bool str_ends_with(const char *string, const char *suffix) {
    int len = strlen(string), suflen = strlen(suffix);
    return len >= suflen && 0 == strcmp(string + len - suflen, suffix);
}

int str_array_index(const char **array, int items, const char *string) {
    for (int i = 0; i < items; ++i)
        if (0 == strcmp(array[i], string))
            return i;
    return -1;
}
