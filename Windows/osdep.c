
#include "osdep.h"
#include "autorelease.h"

#include <assert.h>
#include <windows.h>

const char *os_bundled_resources_path;

static const char *os_get_bundled_resources_path() {
    wchar_t buf[MAX_PATH];
    DWORD rv = GetModuleFileNameW(GetModuleHandle(NULL), buf, sizeof(buf)/sizeof(buf[0]));
    assert(rv);

    char utf[MAX_PATH * 3];
    rv = WideCharToMultiByte(CP_UTF8, 0, buf, -1, utf, sizeof(utf)/sizeof(utf[0]), NULL, NULL);
    assert(rv);

    return strdup(utf);
}

void os_init() {
    os_bundled_resources_path = os_get_bundled_resources_path();
}
