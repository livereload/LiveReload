
#ifndef LiveReload_common_h
#define LiveReload_common_h

#ifdef _MSC_VER

#include <windows.h>
#include <malloc.h>
#include <stdlib.h>

#define __typeof decltype
char *stpcpy(char *dest, const char *source);

const char *basename(const char *path);

static inline WCHAR *_u2w(WCHAR *buf, int cch, const char *utf) {
    MultiByteToWideChar(CP_UTF8, 0, utf, -1, buf, cch);
    return buf;
}

char *w2u(WCHAR *string);

#define U2W(str) _u2w((WCHAR *)_alloca(sizeof(WCHAR) * (strlen(str) + 1)), sizeof(WCHAR) * (strlen(str) + 1), str)

#define _VERIFY(x) do { if (!(x)) abort(); } while(0)
#define VERIFY_BOOL(api) _VERIFY(api)
#define VERIFY_NOT_NULL(api) _VERIFY(api)
#define VERIFY_HRESULT(api) _VERIFY(SUCCEEDED(api))

// some magic to avoid passing hInstance everywhere
// http://blogs.msdn.com/b/oldnewthing/archive/2004/10/25/247180.aspx
EXTERN_C IMAGE_DOS_HEADER __ImageBase;
#define GetCurrentInstance() ((HINSTANCE)&__ImageBase)

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
