#include "mainwnd.h"
#include "mainwnd_projlist.h"
#include "mainwnd_metrics.h"
#include "mainwnd_rpane.h"

#include "autorelease.h"
#include "common.h"
#include "resource.h"
#include "osdep.h"
#include "nodeapi.h"
#include "jansson.h"
#include "msg_proxy.h"
#include "version.h"
#include "widgets.h"


#include <windows.h>
#include <windowsx.h>


static HBITMAP hMainWindowBgBitmap;

static HWND hMainWindow;
static HWND hProjectListView;


enum {
    IDC_ADD_PROJECT_BUTTON,
    IDC_REMOVE_PROJECT_BUTTON,
};

area_t areas[] = {
    { { 65, 492, 28, 22 }, IDC_ADD_PROJECT_BUTTON, mainwnd_projlist_add_project_button_click },
    { { 107, 492, 28, 22 }, IDC_REMOVE_PROJECT_BUTTON, mainwnd_projlist_remove_project_button_click },
};

area_container_t container = { areas, sizeof(areas) / sizeof(areas[0]) };


static void mainwnd_do_layout() {
    RECT client;
    GetClientRect(hMainWindow, &client);
    int width = client.right, height = client.bottom;
    MoveWindow(hProjectListView, kProjectListX, kProjectListY, kProjectListW, kProjectListH, TRUE);

    //HDC hdcScreen = GetDC(NULL);
    //HDC hDC = CreateCompatibleDC(hdcScreen);
    //HBITMAP hBmp = CreateCompatibleBitmap(hdcScreen, width, height);
    //HBITMAP hBmpOld = (HBITMAP)SelectObject(hDC, hBmp);

    //HDC hDC2 = CreateCompatibleDC(hdcScreen);
    //HBITMAP hBmpOld2 = (HBITMAP)SelectObject(hDC2, hMainWindowBgBitmap);

    //// Call UpdateLayeredWindow
    //BLENDFUNCTION blend = {0};
    //blend.BlendOp = AC_SRC_OVER;
    //blend.SourceConstantAlpha = 255;
    //blend.AlphaFormat = AC_SRC_ALPHA;
    //POINT ptPos = {0, 0};
    //SIZE sizeWnd = {width, height};
    //POINT ptSrc = {0, 0};
    //UpdateLayeredWindow(hMainWindow, hdcScreen, NULL, NULL, hDC, &ptSrc, 0, &blend, ULW_ALPHA);

    //SelectObject(hDC, hBmpOld);
    //DeleteObject(hBmp);
    //DeleteDC(hDC);
    //ReleaseDC(NULL, hdcScreen);
}

static void mainwnd_do_paint(HWND hwnd, HDC hDC, RECT *prcPaint) {
    DrawState(hDC, NULL, NULL, (LPARAM)hMainWindowBgBitmap, 0, 0, 0, 0, 0, DST_BITMAP);
    mainwnd_rpane_paint(hDC);
}

static void OnSize(HWND hWnd, UINT state, int cx, int cy) {
    mainwnd_do_layout();
}

static BOOL OnCreate(HWND hwnd, LPCREATESTRUCT lpcs) {
    hMainWindow = hwnd;

    hProjectListView = mainwnd_projlist_create(hwnd);
    mainwnd_rpane_create(hMainWindow);

    mainwnd_do_layout();

    return TRUE;
}

static void OnDestroy(HWND hwnd) {
    PostQuitMessage(0);
}

static void OnPaint(HWND hwnd) {
    PAINTSTRUCT ps;
    BeginPaint(hwnd, &ps);
    mainwnd_do_paint(hwnd, ps.hdc, &ps.rcPaint);
        EndPaint(hwnd, &ps);
}

static void OnPrintClient(HWND hwnd, HDC hdc) {
    RECT rect;
    GetClientRect(hwnd, &rect);
    mainwnd_do_paint(hwnd, hdc, &rect);
}

static DWORD OnNCHitTest(HWND hwnd, int x, int y) {
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

static HBRUSH OnCtlColor(HWND hwnd, HDC hDC, HWND hChildWnd, DWORD dwType) {
    SetBkMode(hDC, TRANSPARENT);
    return (HBRUSH) GetStockObject(NULL_BRUSH);
}

static void OnLButtonDown(HWND hwnd, BOOL fDoubleClick, int x, int y, UINT keyFlags) {
    area_t *area = find_area_by_pt(&container, x, y);
    if (area != NULL && area->on_click) {
        area->on_click(x, y, keyFlags);
    }
}

static LRESULT CALLBACK WndProc(HWND hwnd, UINT uiMsg, WPARAM wParam, LPARAM lParam) {
    switch (uiMsg) {
    HANDLE_MSG(hwnd, WM_CREATE, OnCreate);
    HANDLE_MSG(hwnd, WM_SIZE, OnSize);
    HANDLE_MSG(hwnd, WM_DESTROY, OnDestroy);
    HANDLE_MSG(hwnd, WM_PAINT, OnPaint);
    HANDLE_MSG(hwnd, WM_CTLCOLORLISTBOX, OnCtlColor);
    HANDLE_MSG(hwnd, WM_CTLCOLORSTATIC, OnCtlColor);
    HANDLE_MSG(hwnd, WM_NCHITTEST, OnNCHitTest);
    HANDLE_MSG(hwnd, WM_MEASUREITEM, mainwnd_projlist_measure_item);
    HANDLE_MSG(hwnd, WM_DRAWITEM, mainwnd_projlist_draw_item);
    HANDLE_MSG(hwnd, WM_LBUTTONDOWN, OnLButtonDown);
    case WM_PRINTCLIENT: OnPrintClient(hwnd, (HDC)wParam); return 0;
    }

    return DefWindowProc(hwnd, uiMsg, wParam, lParam);
}

static void mainwnd_register_window_class() {
    WNDCLASS wc;
    wc.style = 0;
    wc.lpfnWndProc = WndProc;
    wc.cbClsExtra = 0;
    wc.cbWndExtra = 0;
    wc.hInstance = GetCurrentInstance();
    wc.hIcon = (HICON) LoadImage(GetCurrentInstance(), MAKEINTRESOURCE(IDI_APP), IMAGE_ICON, 32, 32, LR_DEFAULTCOLOR);
    wc.hCursor = LoadCursor(NULL, IDC_ARROW);
    wc.hbrBackground = (HBRUSH)(COLOR_WINDOW + 1);
    wc.lpszMenuName = NULL;
    wc.lpszClassName = L"LiveReload";

    VERIFY_BOOL(RegisterClass(&wc));
}

static void mainwnd_load_resources() {
    hMainWindowBgBitmap = (HBITMAP) LoadImage(GetCurrentInstance(), MAKEINTRESOURCE(IDB_MAIN_WINDOW_BG), IMAGE_BITMAP, 0, 0, LR_DEFAULTCOLOR);

}

static void mainwnd_create() {
    int width  = kWindowWidth + kOuterShadowLeft + kOuterShadowRight;
    int height = kWindowHeight + kOuterShadowTop + kOuterShadowBottom;

    MONITORINFO mi;
    mi.cbSize = sizeof(mi);
    GetMonitorInfo(MonitorFromWindow(NULL, MONITOR_DEFAULTTOPRIMARY), &mi);
    RECT rcToCenterIn = mi.rcWork;

    int left = (rcToCenterIn.right  + rcToCenterIn.left) / 2 - width / 2;
    int top  = (rcToCenterIn.bottom + rcToCenterIn.top) / 2  - height / 2;

    hMainWindow = CreateWindowEx(0, // removed WS_EX_LAYERED for now
        L"LiveReload",
        L"LiveReload",
        WS_POPUP,
        left, top,
        width, height,
        NULL,
        NULL,
        GetCurrentInstance(),
        0);
    VERIFY_NOT_NULL(hMainWindow);
}

void mainwnd_init() {
    mainwnd_register_window_class();
    mainwnd_load_resources();
    mainwnd_create();
}

void mainwnd_show() {
    ShowWindow(hMainWindow, SW_SHOWDEFAULT);
}

void mainwnd_redraw() {
    // because we've explicitly disabled background painting of the list box (and do not want to subclass
    // it to add proper handling of WM_ERASEBKGND), redraw the whole window
    InvalidateRect(hMainWindow, NULL, TRUE);
}

void mainwnd_paint_region(HDC hDC, RECT rect, HWND hCoordinateWnd) {
    RECT parentRect = rect;
    MapWindowPoints(hCoordinateWnd, hMainWindow, (LPPOINT)&parentRect, 2);

    HDC hBitmapDC = CreateCompatibleDC(hDC);
    HBITMAP hOldBitmap = SelectBitmap(hBitmapDC, hMainWindowBgBitmap);
    BitBlt(hDC, rect.left, rect.top, rect.right-rect.left, rect.bottom-rect.top,
        hBitmapDC, parentRect.left, parentRect.top, SRCCOPY);
    SelectBitmap(hBitmapDC, hOldBitmap);
    DeleteDC(hBitmapDC);
}
