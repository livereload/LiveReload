#ifndef LiveReload_widgets_h
#define LiveReload_widgets_h

#include <windows.h>

typedef struct rect_t {
    int x, y, w, h;
} rect_t;

typedef void (*area_click_func_t)(int x, int y, UINT keyFlags);

typedef struct {
    rect_t rect;
    int id;
    area_click_func_t on_click;
} area_t;

typedef struct {
    area_t *areas;
    int count;
} area_container_t;

area_t *find_area_by_pt(area_container_t *container, int x, int y);

#endif
