#include "autorelease.h"
#include "project.h"
#include "common.h"
#include "resource.h"
#include "osdep.h"
#include "nodeapi.h"
#include "jansson.h"
#include "msg_proxy.h"
#include "version.h"

#include "winsparkle.h"

#include <windows.h>
#include <windowsx.h>
#include <io.h>
#include <ole2.h>
#include <commctrl.h>
#include <ShlObj.h>
#include <ShellAPI.h>
#include <shlwapi.h>
#include <malloc.h>
#include <time.h>

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

json_t *mainwnd_project_list_data = NULL;


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
    IDC_ADD_PROJECT_BUTTON,
    IDC_REMOVE_PROJECT_BUTTON,
};

int CALLBACK add_project_dialog_customizer(HWND hwnd, UINT uMsg, LPARAM lParam, LPARAM lpData) {
    if (uMsg == BFFM_INITIALIZED) {
        SetWindowText(hwnd, L"Add Folder");
    }
    return 0;
}

void add_project_button_click(int x, int y, UINT keyFlags) {
    LPMALLOC pMalloc;
    HRESULT result = SHGetMalloc(&pMalloc);
    assert(SUCCEEDED(result));

    BROWSEINFO bi;
    ZeroMemory (&bi, sizeof(bi));
    bi.lpszTitle = L"Tip: add each web site folder separately.";
    bi.hwndOwner = g_hMainWindow;
    bi.pszDisplayName = NULL;
    bi.pidlRoot = NULL;
    bi.ulFlags = BIF_RETURNONLYFSDIRS | BIF_STATUSTEXT | BIF_USENEWUI;
    bi.lpfn = add_project_dialog_customizer;
    bi.lParam = 0;

    LPITEMIDLIST pidl = SHBrowseForFolder(&bi);
    BOOL success = false;
    wchar_t buf[MAX_PATH];
    if (pidl) {
        success = SHGetPathFromIDList(pidl, buf);
        pMalloc->Free(pidl);
    }

    pMalloc->Release();

    if (success) {
        char *path = w2u(buf);

        json_t *arg = json_object();
        json_object_set_new(arg, "path", json_string(path));
        S_projects_add(arg);

        free(path);
    }
}

void remove_project_button_click(int x, int y, UINT keyFlags) {
    int selection = ListBox_GetCurSel(g_hProjectListView);
    if (selection == LB_ERR)
        return;
    if (!mainwnd_project_list_data)
        return;
    json_t *projects_json = json_object_get(mainwnd_project_list_data, "projects");
    json_t *project_json = json_array_get(projects_json, selection);
    json_t *project_id = json_object_get(project_json, "id");
    if (project_id) {
        json_t *arg = json_object();
        json_object_set(arg, "projectId", project_id);
        S_projects_remove(arg);
    }
}

typedef struct rect_t { int x, y, w, h; } rect_t;
typedef void (*area_click_func_t)(int x, int y, UINT keyFlags);
typedef struct {
    rect_t rect;
    int id;
    area_click_func_t on_click;
} area_t;

area_t areas[] = {
    { { 65, 492, 28, 22 }, IDC_ADD_PROJECT_BUTTON, add_project_button_click },
    { { 107, 492, 28, 22 }, IDC_REMOVE_PROJECT_BUTTON, remove_project_button_click },
};

bool pt_in_rect(int x, int y, rect_t *rect) {
    return x >= rect->x && x < rect->x + rect->w && y >= rect->y && y < rect->y + rect->h;
}

area_t *find_area_by_pt(int x, int y) {
    int count = sizeof(areas)/sizeof(areas[0]);
    for (int i = 0; i < count; i++) {
        if (pt_in_rect(x, y, &areas[i].rect))
            return &areas[i];
    }
    return NULL;
}


enum {
    ID_PROJECT_LIST_VIEW,
};


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

    // because we've explicitly disabled background painting of the list box (and do not want to subclass
    // it to add proper handling of WM_ERASEBKGND), redraw the whole window
    InvalidateRect(g_hMainWindow, NULL, TRUE);
}

void C_mainwnd__set_project_list(json_t *data) {
    if (mainwnd_project_list_data)
        json_decref(mainwnd_project_list_data);
    mainwnd_project_list_data = json_incref(data);
    mainwnd_render_project_list();
}

void C_app__failed_to_start(json_t *arg) {
    MessageBox(NULL, U2W(json_string_value(json_object_get(arg, "message"))), L"LiveReload failed to start", MB_OK | MB_ICONERROR);
    ExitProcess(1);
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

void MainWnd_OnLButtonDown(HWND hwnd, BOOL fDoubleClick, int x, int y, UINT keyFlags) {
    area_t *area = find_area_by_pt(x, y);
    if (area != NULL && area->on_click) {
        area->on_click(x, y, keyFlags);
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
    HANDLE_MSG(hwnd, WM_LBUTTONDOWN, MainWnd_OnLButtonDown);
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
    wc.hIcon = (HICON) LoadImage(g_hinst, MAKEINTRESOURCE(IDI_APP), IMAGE_ICON, 32, 32, LR_DEFAULTCOLOR);
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

// node.js side gets stuck reading from stdin (a bug in Win32 code, I guess), these pings help to unstuck it
void CALLBACK SendRegularPing(HWND, UINT, UINT_PTR, DWORD) {
    S_app_ping(json_object());
}

int WINAPI WinMain(HINSTANCE hinst, HINSTANCE hinstPrev,
                   LPSTR lpCmdLine, int nShowCmd)
{
    MSG msg;
    HWND hwnd;

    if (time(NULL) > 1328054400 /* Feb 1, 2012 UTC */) {
        DWORD result = MessageBox(NULL, L"Sorry, this beta version of LiveReload has expired and cannot be launched.\n\nDo you want to visit http://livereload.com/ to get an updated version?",
            L"LiveReload 2 beta expired", MB_YESNO | MB_ICONERROR);
        if (result == IDYES) {
            ShellExecute(NULL, L"open", L"http://livereload.com/", NULL, NULL, SW_SHOWNORMAL);
        }
        return 1;
    }

    // SHBrowseForFolder needs this, and says it's better to use OleInitialize than ComInitialize
    HRESULT result = OleInitialize(NULL);
    assert(SUCCEEDED(result));

    g_hinst = hinst;
    g_dwMainThreadId = GetCurrentThreadId();

    // create message queue
    PeekMessage(&msg, NULL, WM_USER, WM_USER, PM_NOREMOVE);

    win_sparkle_set_app_details(L"Andrey Tarantsov", L"LiveReload", TEXT(LIVERELOAD_VERSION));
    win_sparkle_set_appcast_url("http://download.livereload.com/LiveReload-Windows-appcast.xml");
    win_sparkle_set_registry_path("Software\\LiveReload\\Updates");

    if (!InitApp()) return 0;

    BOOL outputToConsole = !!strstr(lpCmdLine, "--console");

    os_init(); // to fill in paths before opening log files

    if (outputToConsole) {
        AllocConsole();
        freopen("CONOUT$", "wb", stdout);
        freopen("CONOUT$", "wb", stderr);
    } else {
        WCHAR buf[MAX_PATH];
        MultiByteToWideChar(CP_UTF8, 0, os_log_path, -1, buf, MAX_PATH);
        wcscat(buf, L"\\log.txt");
        _wfreopen(buf, L"w", stderr);
        HANDLE hLogFile = (HANDLE) _get_osfhandle(_fileno(stderr));
        //HANDLE hLogFile = CreateFile(buf, FILE_ALL_ACCESS, FILE_SHARE_WRITE | FILE_SHARE_READ | FILE_SHARE_DELETE, NULL, CREATE_ALWAYS, FILE_FLAG_WRITE_THROUGH, NULL);
        //SetStdHandle(STD_OUTPUT_HANDLE, hLogFile);
        SetStdHandle(STD_ERROR_HANDLE, hLogFile);
    }
    time_t startup_time = time(NULL);
    struct tm *startup_tm = gmtime(&startup_time);
    fprintf(stderr, "LiveReload launched at %04d-%02d-%02d %02d:%02d:%02d\n", 1900 + startup_tm->tm_year,
        1 + startup_tm->tm_mon, startup_tm->tm_mday, startup_tm->tm_hour, startup_tm->tm_min, startup_tm->tm_sec);
    fflush(stderr);

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

    win_sparkle_init();

    SetTimer(NULL, 0, 1000, SendRegularPing);

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

    OleUninitialize();

    return 0;
}
