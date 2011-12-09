
#include "osdep.h"
#include "autorelease.h"

#include <assert.h>
#include <windows.h>

const char *os_bundled_resources_path;
const char *os_bundled_node_path;

static void os_compute_paths() {
    wchar_t buf[MAX_PATH];
    DWORD rv = GetModuleFileNameW(GetModuleHandle(NULL), buf, sizeof(buf)/sizeof(buf[0]));
    assert(rv);

    char utf[MAX_PATH * 3];
    rv = WideCharToMultiByte(CP_UTF8, 0, buf, -1, utf, sizeof(utf)/sizeof(utf[0]), NULL, NULL);
    assert(rv);

    char *backslash = strrchr(utf, '\\');
    char *slash     = strrchr(utf, '/');
    if (backslash || slash) {
        char *sep = (backslash && slash ? __max(backslash, slash) : (backslash ? backslash : slash));
        *sep = 0;
    } else {
        strcpy(utf, ".");
    }

    strcat(utf, "\\..\\Resources");
    os_bundled_resources_path = strdup(utf);

    strcat(utf, "\\node.exe");
    os_bundled_node_path = strdup(utf);
}

void os_init() {
    os_compute_paths();
}
