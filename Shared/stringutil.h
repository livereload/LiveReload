
#ifndef LiveReload_stringutil_h
#define LiveReload_stringutil_h

char *str_replace(const char *string, const char *what, const char *replacement);

const char *str_collapse_paths(const char *text_with_paths, const char *current_project_path);

#endif
