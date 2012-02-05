#include "mainwnd_projlist.h"
#include "mainwnd.h"
#include "mainwnd_metrics.h"

#include "autorelease.h"
#include "common.h"
#include "resource.h"
#include "osdep.h"
#include "jansson.h"
#include "msg_proxy.h"
#include "version.h"

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

static HBITMAP hListBoxSelectionBgBitmap;
static HICON hProjectIcon;
static HFONT hNormalFont12;

static HWND hMainWindow;
static HWND hProjectListView;

static json_t *mainwnd_project_list_data = NULL;


json_t *mainwnd_projlist_get_selected_project_id() {
    int selection;
    if (hProjectListView && (selection = ListBox_GetCurSel(hProjectListView)) != LB_ERR && mainwnd_project_list_data) {
        json_t *projects_json = json_object_get(mainwnd_project_list_data, "projects");
        json_t *project_json = json_array_get(projects_json, selection);
        return json_object_get(project_json, "id");
    } else {
        return json_null();
    }
}

int CALLBACK add_project_dialog_customizer(HWND hwnd, UINT uMsg, LPARAM lParam, LPARAM lpData) {
    if (uMsg == BFFM_INITIALIZED) {
        SetWindowText(hwnd, L"Add Folder");
    }
    return 0;
}

void mainwnd_projlist_add_project_button_click(int x, int y, UINT keyFlags) {
    LPMALLOC pMalloc;
    HRESULT result = SHGetMalloc(&pMalloc);
    assert(SUCCEEDED(result));

    BROWSEINFO bi;
    ZeroMemory (&bi, sizeof(bi));
    bi.lpszTitle = L"Tip: add each web site folder separately.";
    bi.hwndOwner = hMainWindow;
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

void mainwnd_projlist_remove_project_button_click(int x, int y, UINT keyFlags) {
    int selection = ListBox_GetCurSel(hProjectListView);
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

void mainwnd_projlist_measure_item(HWND hwnd, MEASUREITEMSTRUCT * lpMeasureItem) {
    lpMeasureItem->itemHeight = kProjectListItemHeight;
}

void mainwnd_projlist_draw_item(HWND hwnd, const DRAWITEMSTRUCT * lpDrawItem) {
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
                DrawState(lpDrawItem->hDC, NULL, NULL, (LPARAM)hListBoxSelectionBgBitmap, 0, rect.left, rect.top, 0, 0, DST_BITMAP);
            } else {
                mainwnd_paint_region(lpDrawItem->hDC, rect, hProjectListView);
            }
            DrawState(lpDrawItem->hDC, NULL, NULL, (LPARAM)hProjectIcon, 0, rect.left + 18, rect.top + 2, 0, 0, DST_ICON);
            SetTextAlign(lpDrawItem->hDC, TA_TOP | TA_LEFT);
            hOldFont = SelectFont(lpDrawItem->hDC, hNormalFont12);
            if (lpDrawItem->itemState & ODS_SELECTED) {
                SetTextColor(lpDrawItem->hDC, RGB(0xFF, 0xFF, 0xFF));
            } else {
                SetTextColor(lpDrawItem->hDC, RGB(0x00, 0x00, 0x00));
            }
            TextOut(lpDrawItem->hDC, rect.left + 39, rect.top + 1, name, wcslen(name));
            SelectFont(lpDrawItem->hDC, hOldFont);
    }
}

void mainwnd_render_project_list() {
    json_t *projects_json = json_object_get(mainwnd_project_list_data, "projects");
    int count = json_array_size(projects_json);
    ListBox_ResetContent(hProjectListView);
    for (int i = 0; i < count; i++) {
        json_t *project_json = json_array_get(projects_json, i);
        ListBox_AddItemData(hProjectListView, project_json);
    }

    mainwnd_redraw();
}

void C_mainwnd__set_project_list(json_t *data) {
    // preserve selection
    json_t *selected_project_id = mainwnd_projlist_get_selected_project_id();
    json_incref(selected_project_id);

    // save
    if (mainwnd_project_list_data)
        json_decref(mainwnd_project_list_data);
    mainwnd_project_list_data = json_incref(data);

    // render
    mainwnd_render_project_list();

    // restore selection
    int selection_index = -1;
    json_t *projects_json = json_object_get(mainwnd_project_list_data, "projects");
    int count = json_array_size(projects_json);
    for (int i = 0; i < count; i++) {
        json_t *project_id = json_object_get(json_array_get(projects_json, i), "id");
        if (json_equal(project_id, selected_project_id)) {
            selection_index = i;
            break;
        }
    }
    ListBox_SetCurSel(hProjectListView, selection_index);

    json_decref(selected_project_id);
}

HWND mainwnd_projlist_create(HWND _hMainWindow) {
    hMainWindow = _hMainWindow;

    if (!hProjectIcon) {
        hListBoxSelectionBgBitmap = (HBITMAP) LoadImage(GetCurrentInstance(), MAKEINTRESOURCE(IDB_LISTBOX_SELECTION_BG), IMAGE_BITMAP, 0, 0, LR_DEFAULTCOLOR);
        hProjectIcon = (HICON) LoadImage(GetCurrentInstance(), MAKEINTRESOURCE(IDI_FOLDER), IMAGE_ICON, 16, 16, LR_DEFAULTCOLOR);
        hNormalFont12 = CreateFont(-12, 0, 0, 0, FW_NORMAL, FALSE, FALSE, FALSE, DEFAULT_CHARSET, OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS, CLEARTYPE_QUALITY, DEFAULT_PITCH | FF_DONTCARE, L"Lucida Sans Unicode");
    }

    // see http://blogs.msdn.com/b/oldnewthing/archive/2011/10/28/10230811.aspx about WS_EX_TRANSPARENT
    hProjectListView = CreateWindowEx(WS_EX_TRANSPARENT, WC_LISTBOX, L"",
        WS_VISIBLE | WS_CHILD | LBS_NOINTEGRALHEIGHT | LBS_NOTIFY | LBS_OWNERDRAWVARIABLE,
        0, 0, 100, 200, hMainWindow, (HMENU)ID_PROJECT_LIST_VIEW, GetCurrentInstance(), NULL);
    return hProjectListView;
}

void mainwnd_projlist_selection_changed() {
    json_t *arg = json_object();
    json_object_set(arg, "projectId", mainwnd_projlist_get_selected_project_id());
    S_mainwnd_set_selected_project(arg);
}
