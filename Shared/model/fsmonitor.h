
#ifndef LiveReload_fsmonitor_h
#define LiveReload_fsmonitor_h

#include "eventbus.h"

typedef struct fsmonitor_t fsmonitor_t;

fsmonitor_t *fsmonitor_create(const char *path);
void fsmonitor_free(fsmonitor_t *monitor);

EVENTBUS_DECLARE_EVENT(fsmonitor_changed_detected_event);

#endif
