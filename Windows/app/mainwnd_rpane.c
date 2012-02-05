#include "mainwnd_rpane.h"
#include "mainwnd.h"
#include "mainwnd_metrics.h"

#include "autorelease.h"
#include "common.h"
#include "resource.h"
#include "osdep.h"
#include "nodeapi.h"
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

static HBITMAP hProjectPaneBgBitmap;

static HWND hMainWindow;

static json_t *mainwnd_detail_pane_data = NULL;


void mainwnd_rpane_create(HWND _hMainWindow) {
    if (!hWelcomePaneBgBitmap) {
        hProjectPaneBgBitmap = (HBITMAP) LoadImage(GetCurrentInstance(), MAKEINTRESOURCE(IDB_MAINWND_PROJECT_PANE_BG), IMAGE_BITMAP, 0, 0, LR_DEFAULTCOLOR);
    }
    hMainWindow = _hMainWindow;
}

void mainwnd_rpane_update() {

}

void mainwnd_rpane_paint(HDC hDC) {
    DrawState(hDC, NULL, NULL, (LPARAM)hProjectPaneBgBitmap, 0, kProjectPaneX, kProjectPaneY, 0, 0, DST_BITMAP);
}

void C_mainwnd__set_detail_pane_data(json_t *data) {
    if (mainwnd_detail_pane_data)
        json_decref(mainwnd_detail_pane_data);
    mainwnd_detail_pane_data = json_incref(data);
    mainwnd_rpane_update();
}

