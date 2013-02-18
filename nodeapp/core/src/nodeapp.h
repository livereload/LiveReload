#ifndef nodeapp_h
#define nodeapp_h

#include "app_config.h"
#include "app_version.h"

#include "jansson.h"

#ifdef _MSC_VER
#include <windows.h>
#include <malloc.h>
#else
#include <stdbool.h>
#endif

#include <stdlib.h>
#include <string.h>
#include <assert.h>


#ifdef __cplusplus
extern "C" {
#endif


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

#define NSStr(x) ({ const char *__string = (x); (__string ? [NSString stringWithUTF8String:__string] : nil); })
#define nsstrdup(x) (strdup([(x) UTF8String]))
#define json_nsstring_value(x) (NSStr(json_string_value(x)))
#define json_nsstring(x) (json_string([(x) UTF8String]))
#define json_object_get_nsstring(obj, key) (json_nsstring_value(json_object_get(obj, key)))
#define json_object_extract_nsstring(obj, key) (json_nsstring_value(json_object_extract(obj, key)))

#endif

#ifdef __OBJC__
json_t *nodeapp_objc_to_json_or_null(id value);
json_t *nodeapp_objc_to_json(id value);
id nodeapp_json_to_objc(json_t *json, BOOL null_ok);
#endif


////////////////////////////////////////////////////////////////////////////////
// Hash Table

#include "hashtable.h"
    
size_t jsonp_hash_str(const void *ptr);
int jsonp_str_equal(const void *ptr1, const void *ptr2);

////////////////////////////////////////////////////////////////////////////////
// Common Helpers

#define malloc_type(type) ((type *) malloc(sizeof(type)))
    
#define assert0(expr, fmt) if(expr); else (fprintf(stderr, "Assertion failed at %s:%u: %s " fmt, __FILE__, __LINE__, #expr), abort())
#define assert1(expr, fmt, arg1) if(expr); else (fprintf(stderr, "Assertion failed at %s:%u: %s " fmt, __FILE__, __LINE__, #expr, arg1), abort())
#define assert2(expr, fmt, arg1, arg2) if(expr); else (fprintf(stderr, "Assertion failed at %s:%u: %s " fmt, __FILE__, __LINE__, #expr, arg1, arg2), abort())

#define json_set(var, value) do { json_decref(var); (var) = json_incref(value); } while(0)
#define json_bool(val) ((val) ? json_true() : json_false())
#define json_bool_value(val) (json_is_true(val))
    
json_t *json_object_1(const char *key1, json_t *value1);
json_t *json_object_2(const char *key1, json_t *value1, const char *key2, json_t *value2);
json_t *json_object_3(const char *key1, json_t *value1, const char *key2, json_t *value2, const char *key3, json_t *value3);
json_t *json_object_extract(json_t *object, const char *key);

#define json_object_get_string(obj, key) (json_string_value(json_object_get(obj, key)))
#define json_object_extract_string(obj, key) (json_string_value(json_object_extract(obj, key)))

#define ARRAY_FOREACH(type, array, iterVar, code) {\
    type *iterVar##end = (array) + sizeof((array))/sizeof((array)[0]);\
    for(type *iterVar = (array); iterVar < iterVar##end; ++iterVar) {\
        code;\
    }\
}

#define for_each_object_key_value_(object, key, value) \
    for (void *key##_iter = json_object_iter(object); key##_iter && (key = json_object_iter_key(key##_iter)) && (value = json_object_iter_value(key##_iter)); key##_iter = json_object_iter_next(object, key##_iter))

#define for_each_object_key_value(object, key, value) \
    const char *key; \
    json_t *value; \
    for_each_object_key_value_(object, key, value)
    
#define for_each_array_item_(array, index, value) \
    for (size_t index##_size = json_array_size(array), index = 0; index < index##_size && (value = json_array_get(array, index)); ++index)
    
#define for_each_array_item(array, index, value) \
    json_t *value; \
    for_each_array_item_(array, index, value)

char *str_printf(const char *fmt, ...);


////////////////////////////////////////////////////////////////////////////////
// Autorelease

typedef void (*autorelease_func_t)(void *);
void autorelease_custom(autorelease_func_t func, void *data);

void _autorelease_malloced_impl(void *ptr);
json_t *json_autodecref(json_t *json);

#if defined(__MSC_VER) || defined(__cplusplus)
extern "C++" {
    template <typename T>
    inline T *autorelease_malloced(T *val) {
        _autorelease_malloced_impl(val);
        return val;
    }
}
#else
#define autorelease_malloced(val) ({ __typeof(val) __val = val; _autorelease_malloced_impl(__val); __val; })
#endif


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
void nodeapp_reset();

void nodeapp_rpc_send(const char *command, json_t *arg);
void nodeapp_rpc_invoke_and_keep_callback(const char *callback, json_t *arg);
void nodeapp_rpc_invoke_and_dispose_callback(const char *callback, json_t *arg);
void nodeapp_rpc_dispose_callback(const char *callback);

#ifdef __OBJC__
void NodeAppRpcInvokeAndKeepCallback(NSString *callback, id arg);
void NodeAppRpcInvokeAndDisposeCallback(NSString *callback, id arg);
void NodeAppRpcDisposeCallback(NSString *callback);
#endif

typedef void (*INVOKE_LATER_FUNC)(void *);
void nodeapp_invoke_on_main_thread(INVOKE_LATER_FUNC func, void *context);

#ifdef __cplusplus
} // extern "C"
#endif

#endif
