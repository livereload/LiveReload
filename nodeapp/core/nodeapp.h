#ifndef nodeapp_h
#define nodeapp_h

#include "app_config.h"
#include "app_version.h"

#include "jansson.h"

#ifdef _MSC_VER
#include <windows.h>
#include <malloc.h>
#endif

#include <stdlib.h>
#include <string.h>


////////////////////////////////////////////////////////////////////////////////
// Windows Helpers

#ifdef _MSC_VER

#define __typeof decltype

char *stpcpy(char *dest, const char *source);
int vasprintf(char **sptr, const char *fmt, va_list argv);
int asprintf(char **sptr, const char *fmt, ... );

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


////////////////////////////////////////////////////////////////////////////////
// Mac Helpers

#ifdef __APPLE__

#define NSStr(x) ((x) ? [NSString stringWithUTF8String:(x)] : nil)
#define nsstrdup(x) (strdup([(x) UTF8String]))
#define json_nsstring_value(x) (NSStr(json_string_value(x)))

#endif

#ifdef __OBJC__
json_t *objc_to_json(id value);
#endif


////////////////////////////////////////////////////////////////////////////////
// Common Helpers

#define json_set(var, value) do { json_decref(var); (var) = json_incref(value); } while(0)
#define json_bool(val) ((val) ? json_true() : json_false())

#define ARRAY_FOREACH(type, array, iterVar, code) {\
    type *iterVar##end = (array) + sizeof((array))/sizeof((array)[0]);\
    for(type *iterVar = (array); iterVar < iterVar##end; ++iterVar) {\
        code;\
    }\
}

char *str_printf(const char *fmt, ...);


////////////////////////////////////////////////////////////////////////////////
// Main NodeApp API

extern const char *nodeapp_bundled_resources_dir;
extern const char *nodeapp_bundled_node_path;
extern const char *nodeapp_bundled_backend_js;
extern const char *nodeapp_appdata_dir;
extern const char *nodeapp_log_dir;
extern const char *nodeapp_log_file;

void nodeapp_init();
void nodeapp_shutdown();

void nodeapp_rpc_send(const char *command, json_t *arg);

typedef void (*INVOKE_LATER_FUNC)(void *);
void nodeapp_invoke_on_main_thread(INVOKE_LATER_FUNC func, void *context);

#endif
