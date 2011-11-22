#include "autorelease.h"
#include "project.h"
#include "common.h"
#include "resource.h"

#include <windows.h>
#include <windowsx.h>
#include <ole2.h>
#include <commctrl.h>
#include <ShellAPI.h>
#include <shlwapi.h>
#include <malloc.h>

#include <assert.h>

HINSTANCE g_hinst;
HBITMAP g_hMainWindowBgBitmap;
HWND g_hMainWindow;
HWND g_hwndChild;
HWND g_hwndProjectListView;
HIMAGELIST g_hSmallImageList;

enum {
    ID_PROJECT_LIST_VIEW,
};

void LayoutSubviews() {
    RECT client;
    GetClientRect(g_hMainWindow, &client);
    int width = client.right, height = client.bottom;
    MoveWindow(g_hwndProjectListView, 0, 22, 202, 470, TRUE);
}

void OnSize(HWND hwnd, UINT state, int cx, int cy) {
    LayoutSubviews();
}

BOOL OnCreate(HWND hwnd, LPCREATESTRUCT lpcs) {
    g_hMainWindow = hwnd;
    g_hwndProjectListView = CreateWindow(WC_LISTVIEW, L"", WS_VISIBLE | WS_CHILD | LVS_LIST | LVS_SINGLESEL,
        0, 0, 100, 200, hwnd, (HMENU) ID_PROJECT_LIST_VIEW, g_hinst, NULL);
    g_hSmallImageList = ImageList_Create(16, 16, ILC_MASK | ILC_COLOR32, 3, 0);

    WCHAR buf[MAX_PATH];
    GetWindowsDirectory(buf, sizeof(buf)/sizeof(buf[0]));

    SHFILEINFO file_info;
    DWORD_PTR result = SHGetFileInfo(buf, 0, &file_info, sizeof(file_info), SHGFI_ICON | SHGFI_SMALLICON);
    assert(result);

    ImageList_AddIcon(g_hSmallImageList, file_info.hIcon);
    //DestroyIcon(file_info.hIcon);

    assert(ImageList_GetImageCount(g_hSmallImageList) == 1);

    ListView_SetImageList(g_hwndProjectListView, g_hSmallImageList, LVSIL_SMALL);

    LVCOLUMN col;
    col.mask = LVCF_FMT | LVCF_WIDTH | LVCF_TEXT;
    col.fmt = LVCFMT_LEFT;
    col.cx = 75;
    col.pszText = L"Folder";
    ListView_InsertColumn(g_hwndProjectListView, 0, &col);

    LV_ITEM item;
    item.mask = LVIF_TEXT | LVIF_IMAGE | LVIF_STATE;
    item.iImage = 0;
    item.state = 0;
    item.stateMask = 0;
    item.iSubItem = 0;
    item.cchTextMax = 255;

    int count = project_count();
    for (int i = 0; i < count; i++) {
        project_t *project = project_get(i);
        item.iItem = i;
        item.pszText = U2W(project_display_path(project));
        result = ListView_InsertItem(g_hwndProjectListView, &item);
        assert(result >= 0);
    }

    LayoutSubviews();

    return TRUE;
}

void OnDestroy(HWND hwnd) {
    PostQuitMessage(0);
}

void PaintContent(HWND hwnd, PAINTSTRUCT *pps) {
    HDC hDC = pps->hdc;
    DrawState(hDC, NULL, NULL, (LPARAM)g_hMainWindowBgBitmap, 0, 0, 0, 0, 0, DST_BITMAP);
}

void OnPaint(HWND hwnd) {
    PAINTSTRUCT ps;
    BeginPaint(hwnd, &ps);
    PaintContent(hwnd, &ps);
    EndPaint(hwnd, &ps);
}

void OnPrintClient(HWND hwnd, HDC hdc) {
    PAINTSTRUCT ps;
    ps.hdc = hdc;
    GetClientRect(hwnd, &ps.rcPaint);
    PaintContent(hwnd, &ps);

}

LRESULT CALLBACK WndProc(HWND hwnd, UINT uiMsg, WPARAM wParam, LPARAM lParam) {
    switch (uiMsg) {
    HANDLE_MSG(hwnd, WM_CREATE, OnCreate);
    HANDLE_MSG(hwnd, WM_SIZE, OnSize);
    HANDLE_MSG(hwnd, WM_DESTROY, OnDestroy);
    HANDLE_MSG(hwnd, WM_PAINT, OnPaint);
    case WM_PRINTCLIENT: OnPrintClient(hwnd, (HDC)wParam); return 0;
    }

    return DefWindowProc(hwnd, uiMsg, wParam, lParam);
}

BOOL InitApp(void) {
    WNDCLASS wc;

    wc.style = 0;
    wc.lpfnWndProc = WndProc;
    wc.cbClsExtra = 0;
    wc.cbWndExtra = 0;
    wc.hInstance = g_hinst;
    wc.hIcon = NULL;
    wc.hCursor = LoadCursor(NULL, IDC_ARROW);
    wc.hbrBackground = (HBRUSH)(COLOR_WINDOW + 1);
    wc.lpszMenuName = NULL;
    wc.lpszClassName = L"LiveReload";

    if (!RegisterClass(&wc)) return FALSE;

    INITCOMMONCONTROLSEX sex;
    sex.dwSize = sizeof(sex);
    sex.dwICC = ICC_WIN95_CLASSES | ICC_LINK_CLASS;
    InitCommonControlsEx(&sex);

    return TRUE;
}

DWORD g_dwMainThreadId;
enum { AM_INVOKE = WM_APP + 1 };
void invoke_on_main_thread(INVOKE_LATER_FUNC func, void *context) {
  PostThreadMessage(g_dwMainThreadId, AM_INVOKE, (WPARAM)func, (LPARAM) context);
}

int WINAPI WinMain(HINSTANCE hinst, HINSTANCE hinstPrev,
                   LPSTR lpCmdLine, int nShowCmd)
{
    MSG msg;
    HWND hwnd;

    g_hinst = hinst;
    g_dwMainThreadId = GetCurrentThreadId();

    // create message queue
    PeekMessage(&msg, NULL, WM_USER, WM_USER, PM_NOREMOVE);

    if (!InitApp()) return 0;

    AllocConsole();
    freopen("CONOUT$", "wb", stdout);

    project_add_new("c:\\Dropbox\\GitHub\\LiveReload2");
    project_add_new("c:\\Dropbox\\GitHub\\keymapper_tip");

    g_hMainWindowBgBitmap = (HBITMAP) LoadImage(g_hinst, MAKEINTRESOURCE(IDB_MAIN_WINDOW_BG), IMAGE_BITMAP, 0, 0, LR_DEFAULTCOLOR);


    DWORD dwStyle = WS_POPUP;

    RECT rect = {0, 0, 0, 0};
    rect.right = 738;
    rect.bottom = 514;
    AdjustWindowRectEx(&rect, dwStyle, FALSE, 0);

    int height = rect.bottom - rect.top, width = rect.right - rect.left;

    MONITORINFO mi;
    mi.cbSize = sizeof(mi);
    GetMonitorInfo(MonitorFromWindow(NULL, MONITOR_DEFAULTTOPRIMARY), &mi);
    RECT rcToCenterIn = mi.rcWork;

    int left = (rcToCenterIn.right  + rcToCenterIn.left) / 2 - width / 2;
    int top  = (rcToCenterIn.bottom + rcToCenterIn.top) / 2  - height / 2;

    hwnd = CreateWindow(
        L"LiveReload",
        L"LiveReload",
        dwStyle,
        left, top,
        width, height,
        NULL,
        NULL,
        hinst,
        0);

    ShowWindow(hwnd, nShowCmd);

    while (GetMessage(&msg, NULL, 0, 0)) {
        if (msg.message == AM_INVOKE && msg.hwnd == NULL) {
          INVOKE_LATER_FUNC func = (INVOKE_LATER_FUNC)msg.wParam;
          void *context = (void *)msg.lParam;
          func(context);
        } else {
          TranslateMessage(&msg);
          DispatchMessage(&msg);
        }
        autorelease_cleanup();
    }

    return 0;
}
