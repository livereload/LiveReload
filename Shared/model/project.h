
#ifndef LiveReload_project_h
#define LiveReload_project_h

#include "jansson.h"
#include "eventbus.h"

#include <stdbool.h>


EVENTBUS_DECLARE_EVENT(project_did_detect_change_event);


typedef enum {
    project_monitoring_reason_browser_connected,
    project_monitoring_reason_compilation_enabled,
} project_monitoring_reason;


typedef struct project_t project_t;


int project_count();
project_t *project_get(int index);
void project_add_new(const char *path);


project_t *project_create(const char *path, json_t *memento);
void project_free(project_t *project);

json_t *project_memento(project_t *project);

const char *project_name(project_t *project);
char *project_display_path(project_t *project);

void project_set_live_refresh_enabled(project_t *project, bool enabled);
void project_set_full_page_reload_delay(project_t *project, float delay);

void project_request_monitoring(project_t *project, project_monitoring_reason reason, bool enable);

// checks for FSEvents bugs on OS X
void project_verify_monitoring_possibility(project_t *project);


#endif
