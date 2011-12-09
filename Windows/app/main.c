#include "autorelease.h"
#include "project.h"
#include "common.h"
#include "resource.h"
#include "osdep.h"
#include "nodeapi.h"
#include "jansson.h"

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

HFONT g_hNormalFont12;

WNDPROC g_originalListViewWndProc;
HWND g_hProjectListView;
HICON g_hProjectIcon;
HBITMAP g_hListBoxSelectionBgBitmap;

HBITMAP g_hProjectPaneBgBitmap;

//#define kOuterShadowLeft   57
//#define kOuterShadowTop    35
//#define kOuterShadowRight  57
//#define kOuterShadowBottom 78
#define kOuterShadowLeft   0
#define kOuterShadowTop    0
#define kOuterShadowRight  0
#define kOuterShadowBottom 0

#define kTitleBarHeight  22
#define kBottomBarHeight 22
#define kWindowWidth     738
#define kWindowHeight    514
#define kClientAreaX kOuterShadowLeft
#define kClientAreaY (kOuterShadowTop + kTitleBarHeight)
#define kClientAreaWidth  kWindowWidth
#define kClientAreaHeight (kWindowHeight - kTitleBarHeight)

#define kProjectListX kClientAreaX
#define kProjectListY kClientAreaY
#define kProjectListW 202
#define kProjectListH (kClientAreaHeight - kBottomBarHeight)
#define kProjectListItemHeight 20

#define kProjectPaneX (kProjectListX + kProjectListW)
#define kProjectPaneY kClientAreaY
#define kProjectPaneW (kClientAreaWidth - kProjectListW)
#define kProjectPaneH kProjectListH

enum {
    ID_PROJECT_LIST_VIEW,
};


json_t *mainwnd_project_list_data = NULL;


void LayoutSubviews() {
    RECT client;
    GetClientRect(g_hMainWindow, &client);
    int width = client.right, height = client.bottom;
    MoveWindow(g_hProjectListView, kProjectListX, kProjectListY, kProjectListW, kProjectListH, TRUE);

    //HDC hdcScreen = GetDC(NULL);
    //HDC hDC = CreateCompatibleDC(hdcScreen);
    //HBITMAP hBmp = CreateCompatibleBitmap(hdcScreen, width, height);
    //HBITMAP hBmpOld = (HBITMAP)SelectObject(hDC, hBmp);

    //HDC hDC2 = CreateCompatibleDC(hdcScreen);
    //HBITMAP hBmpOld2 = (HBITMAP)SelectObject(hDC2, g_hMainWindowBgBitmap);

    //// Call UpdateLayeredWindow
    //BLENDFUNCTION blend = {0};
    //blend.BlendOp = AC_SRC_OVER;
    //blend.SourceConstantAlpha = 255;
    //blend.AlphaFormat = AC_SRC_ALPHA;
    //POINT ptPos = {0, 0};
    //SIZE sizeWnd = {width, height};
    //POINT ptSrc = {0, 0};
    //UpdateLayeredWindow(g_hMainWindow, hdcScreen, NULL, NULL, hDC, &ptSrc, 0, &blend, ULW_ALPHA);

    //SelectObject(hDC, hBmpOld);
    //DeleteObject(hBmp);
    //DeleteDC(hDC);
    //ReleaseDC(NULL, hdcScreen);
}

void mainwnd_render_project_list() {
    json_t *projects_json = json_object_get(mainwnd_project_list_data, "projects");
    int count = json_array_size(projects_json);
    ListBox_ResetContent(g_hProjectListView);
    for (int i = 0; i < count; i++) {
        json_t *project_json = json_array_get(projects_json, i);
        ListBox_AddItemData(g_hProjectListView, project_json);
    }

    ListBox_SetCurSel(g_hProjectListView, 0);
}

void mainwnd_set_project_list(json_t *data) {
    if (mainwnd_project_list_data)
        json_decref(mainwnd_project_list_data);
    mainwnd_project_list_data = json_incref(data);
    mainwnd_render_project_list();
}

void OnSize(HWND hWnd, UINT state, int cx, int cy) {
    LayoutSubviews();
}

BOOL OnCreate(HWND hwnd, LPCREATESTRUCT lpcs) {
    g_hMainWindow = hwnd;

    // see http://blogs.msdn.com/b/oldnewthing/archive/2011/10/28/10230811.aspx about WS_EX_TRANSPARENT
    g_hProjectListView = CreateWindowEx(WS_EX_TRANSPARENT, WC_LISTBOX, L"",
        WS_VISIBLE | WS_CHILD |    LBS_NOINTEGRALHEIGHT | LBS_NOTIFY | LBS_OWNERDRAWVARIABLE,
        0, 0, 100, 200, hwnd, (HMENU) ID_PROJECT_LIST_VIEW, g_hinst, NULL);

    LayoutSubviews();

    return TRUE;
}

void OnDestroy(HWND hwnd) {
    PostQuitMessage(0);
}

void MainWnd_PaintContent(HWND hwnd, HDC hDC, RECT *prcPaint) {
    DrawState(hDC, NULL, NULL, (LPARAM)g_hMainWindowBgBitmap, 0, 0, 0, 0, 0, DST_BITMAP);
    DrawState(hDC, NULL, NULL, (LPARAM)g_hProjectPaneBgBitmap, 0, kProjectPaneX, kProjectPaneY, 0, 0, DST_BITMAP);
}

void OnPaint(HWND hwnd) {
    PAINTSTRUCT ps;
    BeginPaint(hwnd, &ps);
    MainWnd_PaintContent(hwnd, ps.hdc, &ps.rcPaint);
    EndPaint(hwnd, &ps);
}

void OnPrintClient(HWND hwnd, HDC hdc) {
    RECT rect;
    GetClientRect(hwnd, &rect);
    MainWnd_PaintContent(hwnd, hdc, &rect);
}

DWORD OnNCHitTest(HWND hwnd, int x, int y) {
    RECT rect;
    GetWindowRect(hwnd, &rect);
    x -= rect.left;
    y -= rect.top;

    if (y <= kTitleBarHeight) {
        if (x >= 15 && x <= 25)
            return HTSYSMENU;
        if (x >= 700)
            return HTCLOSE;
        return HTCAPTION;
    }
    return HTCLIENT;
}

HBRUSH OnCtlColor(HWND hwnd, HDC hDC, HWND hChildWnd, DWORD dwType) {
    SetBkMode(hDC, TRANSPARENT);
    return (HBRUSH) GetStockObject(NULL_BRUSH);
}

void MainWnd_OnMeasureItem(HWND hwnd, MEASUREITEMSTRUCT * lpMeasureItem) {
    lpMeasureItem->itemHeight = kProjectListItemHeight;
}

void MainWnd_OnDrawItem(HWND hwnd, const DRAWITEMSTRUCT * lpDrawItem) {
    if (lpDrawItem->itemID == -1)
        return;
    RECT rect = lpDrawItem->rcItem;

    json_t *projects_json = json_object_get(mainwnd_project_list_data, "projects");
    json_t *project_json = json_array_get(projects_json, lpDrawItem->itemID);
    WCHAR *name = U2W(json_string_value(json_object_get(project_json, "name")));
    HFONT hOldFont;

    // http://www.codeproject.com/KB/combobox/TransListBox.aspx
    switch (lpDrawItem->itemAction) {
        case ODA_SELECT:
        case ODA_DRAWENTIRE:
            if (lpDrawItem->itemState & ODS_SELECTED) {
                DrawState(lpDrawItem->hDC, NULL, NULL, (LPARAM)g_hListBoxSelectionBgBitmap, 0, rect.left, rect.top, 0, 0, DST_BITMAP);
            } else {
                RECT parentRect = rect;
                MapWindowPoints(g_hProjectListView, g_hMainWindow, (LPPOINT)&parentRect, 2);

                HDC hBitmapDC = CreateCompatibleDC(lpDrawItem->hDC);
                HBITMAP hOldBitmap = SelectBitmap(hBitmapDC, g_hMainWindowBgBitmap);
                BitBlt(lpDrawItem->hDC, rect.left, rect.top, rect.right-rect.left, rect.bottom-rect.top,
                    hBitmapDC, parentRect.left, parentRect.top, SRCCOPY);
                SelectBitmap(hBitmapDC, hOldBitmap);
                DeleteDC(hBitmapDC);
            }
            DrawState(lpDrawItem->hDC, NULL, NULL, (LPARAM)g_hProjectIcon, 0, rect.left + 18, rect.top + 2, 0, 0, DST_ICON);
            SetTextAlign(lpDrawItem->hDC, TA_TOP | TA_LEFT);
            hOldFont = SelectFont(lpDrawItem->hDC, g_hNormalFont12);
            if (lpDrawItem->itemState & ODS_SELECTED) {
                SetTextColor(lpDrawItem->hDC, RGB(0xFF, 0xFF, 0xFF));
            } else {
                SetTextColor(lpDrawItem->hDC, RGB(0x00, 0x00, 0x00));
            }
            TextOut(lpDrawItem->hDC, rect.left + 39, rect.top + 1, name, wcslen(name));
            SelectFont(lpDrawItem->hDC, hOldFont);
    }
}

LRESULT CALLBACK WndProc(HWND hwnd, UINT uiMsg, WPARAM wParam, LPARAM lParam) {
    switch (uiMsg) {
    HANDLE_MSG(hwnd, WM_CREATE, OnCreate);
    HANDLE_MSG(hwnd, WM_SIZE, OnSize);
    HANDLE_MSG(hwnd, WM_DESTROY, OnDestroy);
    HANDLE_MSG(hwnd, WM_PAINT, OnPaint);
    HANDLE_MSG(hwnd, WM_CTLCOLORLISTBOX, OnCtlColor);
    HANDLE_MSG(hwnd, WM_CTLCOLORSTATIC, OnCtlColor);
    HANDLE_MSG(hwnd, WM_NCHITTEST, OnNCHitTest);
    HANDLE_MSG(hwnd, WM_MEASUREITEM, MainWnd_OnMeasureItem);
    HANDLE_MSG(hwnd, WM_DRAWITEM, MainWnd_OnDrawItem);
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
    freopen("CONOUT$", "wb", stderr);

    os_init();
    node_init();

    project_add_new("c:\\Dropbox\\GitHub\\LiveReload2");
    project_add_new("c:\\Dropbox\\GitHub\\keymapper_tip");

    g_hMainWindowBgBitmap = (HBITMAP) LoadImage(g_hinst, MAKEINTRESOURCE(IDB_MAIN_WINDOW_BG), IMAGE_BITMAP, 0, 0, LR_DEFAULTCOLOR);
    g_hListBoxSelectionBgBitmap = (HBITMAP) LoadImage(g_hinst, MAKEINTRESOURCE(IDB_LISTBOX_SELECTION_BG), IMAGE_BITMAP, 0, 0, LR_DEFAULTCOLOR);
    g_hProjectPaneBgBitmap = (HBITMAP) LoadImage(g_hinst, MAKEINTRESOURCE(IDB_MAINWND_PROJECT_PANE_BG), IMAGE_BITMAP, 0, 0, LR_DEFAULTCOLOR);

    g_hProjectIcon = (HICON) LoadImage(g_hinst, MAKEINTRESOURCE(IDI_FOLDER), IMAGE_ICON, 16, 16, LR_DEFAULTCOLOR);

    g_hNormalFont12 = CreateFont(-12, 0, 0, 0, FW_NORMAL, FALSE, FALSE, FALSE, DEFAULT_CHARSET, OUT_DEFAULT_PRECIS,
        CLIP_DEFAULT_PRECIS, CLEARTYPE_QUALITY, DEFAULT_PITCH | FF_DONTCARE, L"Lucida Sans Unicode");

    int width  = kWindowWidth + kOuterShadowLeft + kOuterShadowRight;
    int height = kWindowHeight + kOuterShadowTop + kOuterShadowBottom;

    MONITORINFO mi;
    mi.cbSize = sizeof(mi);
    GetMonitorInfo(MonitorFromWindow(NULL, MONITOR_DEFAULTTOPRIMARY), &mi);
    RECT rcToCenterIn = mi.rcWork;

    int left = (rcToCenterIn.right  + rcToCenterIn.left) / 2 - width / 2;
    int top  = (rcToCenterIn.bottom + rcToCenterIn.top) / 2  - height / 2;

    hwnd = CreateWindowEx(0, // removed WS_EX_LAYERED for now
        L"LiveReload",
        L"LiveReload",
        WS_POPUP,
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

    node_shutdown();

    return 0;
}
