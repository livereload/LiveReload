#include "common.h"
#include "osdep.h"
#include "autorelease.h"

#include <assert.h>
#include <windows.h>
#include <shlobj.h>

const char *os_bundled_resources_path;
const char *os_bundled_backend_path;
const char *os_bundled_node_path;
const char *os_preferences_path;
const char *os_log_path;

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

    LPWSTR command_line = GetCommandLine();
    BOOL dev_mode = !!wcsstr(command_line, L"--dev");

    strcat(utf, "\\Resources");
    os_bundled_resources_path = strdup(utf);

    strcat(utf, "\\node.exe");
    os_bundled_node_path = strdup(utf);

    strcpy(utf, os_bundled_resources_path);
    if (dev_mode)
        strcat(utf, "\\..\\..\\backend");
    else
        strcat(utf, "\\backend");
    os_bundled_backend_path = strdup(utf);

    rv = SHGetSpecialFolderPath(NULL, buf, CSIDL_APPDATA, TRUE);
    assert(rv);
    wcscat(buf, L"\\LiveReload");
    CreateDirectory(buf, NULL);
    os_preferences_path = w2u(buf);

    rv = SHGetSpecialFolderPath(NULL, buf, CSIDL_LOCAL_APPDATA, TRUE);
    assert(rv);
    wcscat(buf, L"\\LiveReload");
    CreateDirectory(buf, NULL);
    wcscat(buf, L"\\Logs");
    CreateDirectory(buf, NULL);
    os_log_path = w2u(buf);
}

void os_init() {
    os_compute_paths();
}
