#ifndef LiveReload_mainwnd_h
#define LiveReload_mainwnd_h

#include <windows.h>

void mainwnd_init();
void mainwnd_show();

/* poor man's transparency requires explicit repaints */
void mainwnd_redraw();
void mainwnd_paint_region(HDC hDC, RECT rect, HWND hCoordinateWnd);

#endif
