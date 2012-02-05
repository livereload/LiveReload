#ifndef LiveReload_mainwnd_projlist_h
#define LiveReload_mainwnd_projlist_h

#include <windows.h>

void mainwnd_projlist_measure_item(HWND hwnd, MEASUREITEMSTRUCT * lpMeasureItem);
void mainwnd_projlist_draw_item(HWND hwnd, const DRAWITEMSTRUCT * lpDrawItem);

void mainwnd_projlist_add_project_button_click(int x, int y, UINT keyFlags);
void mainwnd_projlist_remove_project_button_click(int x, int y, UINT keyFlags);

HWND mainwnd_projlist_create(HWND hMainWindow);

void mainwnd_projlist_selection_changed();

#endif
