
#ifndef LiveReload_stringutil_h
#define LiveReload_stringutil_h

#include <stdbool.h>

char *str_replace(const char *string, const char *what, const char *replacement);

const char *str_collapse_paths(const char *text_with_paths, const char *current_project_path);

bool str_starts_with(const char *string, const char *suffix);

bool str_ends_with(const char *string, const char *suffix);

int str_array_index(const char **array, int items, const char *string);

#define str_static_array_index(array, string) str_array_index((array), sizeof(array)/sizeof((array)[0]), string)

#endif
