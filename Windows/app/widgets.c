#include "widgets.h"

bool pt_in_rect(int x, int y, rect_t *rect) {
    return x >= rect->x && x < rect->x + rect->w && y >= rect->y && y < rect->y + rect->h;
}

area_t *find_area_by_pt(area_container_t *container, int x, int y) {
    area_t *areas = container->areas;
    int count = container->count;
    for (int i = 0; i < count; i++) {
        if (pt_in_rect(x, y, &areas[i].rect))
            return &areas[i];
    }
    return NULL;
}
