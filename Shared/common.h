
#ifndef LiveReload_common_h
#define LiveReload_common_h

#ifdef _MSC_VER

#include <windows.h>
#include <malloc.h>

#define __typeof decltype
char *stpcpy(char *dest, const char *source);

const char *basename(const char *path);

static inline WCHAR *_u2w(WCHAR *buf, int cch, const char *utf) {
    MultiByteToWideChar(CP_UTF8, 0, utf, -1, buf, cch);
    return buf;
}

char *w2u(WCHAR *string);

#define U2W(str) _u2w((WCHAR *)_alloca(sizeof(WCHAR) * (strlen(str) + 1)), sizeof(WCHAR) * (strlen(str) + 1), str)

#endif

#define ARRAY_FOREACH(type, array, iterVar, code) {\
    type *iterVar##end = (array) + sizeof((array))/sizeof((array)[0]);\
    for(type *iterVar = (array); iterVar < iterVar##end; ++iterVar) {\
        code;\
    }\
}

typedef void (*INVOKE_LATER_FUNC)(void *);
void invoke_on_main_thread(INVOKE_LATER_FUNC func, void *context);

#endif
