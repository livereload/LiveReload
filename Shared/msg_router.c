#include "msg_router.h"
#include <stddef.h>
#include <string.h>

typedef struct {
    const char   *api_name;
    msg_func_t    func;
} msg_entry_t;

void C_monitoring__add(json_t *data);
json_t *C_monitoring__remove(json_t *data);
void C_app__failed_to_start(json_t *data);
void C_mainwnd__set_project_list(json_t *data);
void C_mainwnd__rpane__set_data(json_t *data);
void C_mainwnd__set_connection_status(json_t *data);
void C_mainwnd__set_change_count(json_t *data);
void C_workspace__set_monitoring_enabled(json_t *data);

json_t *_C_monitoring__add_wrapper(json_t *data) {
    C_monitoring__add(data);
    return NULL;
}

json_t *_C_app__failed_to_start_wrapper(json_t *data) {
    C_app__failed_to_start(data);
    return NULL;
}

json_t *_C_mainwnd__set_project_list_wrapper(json_t *data) {
    C_mainwnd__set_project_list(data);
    return NULL;
}

json_t *_C_mainwnd__rpane__set_data_wrapper(json_t *data) {
    C_mainwnd__rpane__set_data(data);
    return NULL;
}

json_t *_C_mainwnd__set_connection_status_wrapper(json_t *data) {
    C_mainwnd__set_connection_status(data);
    return NULL;
}

json_t *_C_mainwnd__set_change_count_wrapper(json_t *data) {
    C_mainwnd__set_change_count(data);
    return NULL;
}

json_t *_C_workspace__set_monitoring_enabled_wrapper(json_t *data) {
    C_workspace__set_monitoring_enabled(data);
    return NULL;
}

msg_entry_t entries[] = {
    { "monitoring.add", &_C_monitoring__add_wrapper },
    { "monitoring.remove", &C_monitoring__remove },
    { "app.failed_to_start", &_C_app__failed_to_start_wrapper },
    { "mainwnd.set_project_list", &_C_mainwnd__set_project_list_wrapper },
    { "mainwnd.rpane.set_data", &_C_mainwnd__rpane__set_data_wrapper },
    { "mainwnd.set_connection_status", &_C_mainwnd__set_connection_status_wrapper },
    { "mainwnd.set_change_count", &_C_mainwnd__set_change_count_wrapper },
    { "workspace.set_monitoring_enabled", &_C_workspace__set_monitoring_enabled_wrapper },
    { NULL, NULL }
};

msg_func_t find_msg_handler(const char *api_name) {
    for (msg_entry_t *entry = entries; entry->api_name; entry++) {
        if (0 == strcmp(api_name, entry->api_name))
            return entry->func;
    }
    return NULL;
}
