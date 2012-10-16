#include "nodeapp_rpc_router.h"

#include <stddef.h>
#include <string.h>

typedef struct {
    const char   *api_name;
    msg_func_t    func;
} msg_entry_t;

void C_broker__unretain(json_t *data);
void C_monitoring__add(json_t *data);
json_t *C_monitoring__remove(json_t *data);
void C_ui__update(json_t *data);
json_t *C_app__display_popup_message(json_t *data);
void C_app__reveal_file(json_t *data);
void C_app__open_url(json_t *data);
void C_app__terminate(json_t *data);
json_t *C_preferences__read(json_t *data);
json_t *C_licensing__verify_receipt(json_t *data);
void C_mainwnd__set_project_list(json_t *data);
void C_mainwnd__rpane__set_data(json_t *data);
void C_app__good_time_to_deliver_news(json_t *data);
void C_update(json_t *data);
void C_app__failed_to_start(json_t *data);
void C_mainwnd__set_connection_status(json_t *data);
void C_mainwnd__set_change_count(json_t *data);
void C_workspace__set_monitoring_enabled(json_t *data);
void C_app__request_model(json_t *data);
json_t *C_project__path_of_best_file_matching_path_suffix(json_t *data);

json_t *_C_broker__unretain_wrapper(json_t *data) {
    C_broker__unretain(data);
    return NULL;
}

json_t *_C_monitoring__add_wrapper(json_t *data) {
    C_monitoring__add(data);
    return NULL;
}

json_t *_C_ui__update_wrapper(json_t *data) {
    C_ui__update(data);
    return NULL;
}

json_t *_C_app__reveal_file_wrapper(json_t *data) {
    C_app__reveal_file(data);
    return NULL;
}

json_t *_C_app__open_url_wrapper(json_t *data) {
    C_app__open_url(data);
    return NULL;
}

json_t *_C_app__terminate_wrapper(json_t *data) {
    C_app__terminate(data);
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

json_t *_C_app__good_time_to_deliver_news_wrapper(json_t *data) {
    C_app__good_time_to_deliver_news(data);
    return NULL;
}

json_t *_C_update_wrapper(json_t *data) {
    C_update(data);
    return NULL;
}

json_t *_C_app__failed_to_start_wrapper(json_t *data) {
    C_app__failed_to_start(data);
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

json_t *_C_app__request_model_wrapper(json_t *data) {
    C_app__request_model(data);
    return NULL;
}

msg_entry_t entries[] = {
    { "broker.unretain", &_C_broker__unretain_wrapper },
    { "monitoring.add", &_C_monitoring__add_wrapper },
    { "monitoring.remove", &C_monitoring__remove },
    { "ui.update", &_C_ui__update_wrapper },
    { "app.display_popup_message", &C_app__display_popup_message },
    { "app.reveal_file", &_C_app__reveal_file_wrapper },
    { "app.open_url", &_C_app__open_url_wrapper },
    { "app.terminate", &_C_app__terminate_wrapper },
    { "preferences.read", &C_preferences__read },
    { "licensing.verify_receipt", &C_licensing__verify_receipt },
    { "mainwnd.set_project_list", &_C_mainwnd__set_project_list_wrapper },
    { "mainwnd.rpane.set_data", &_C_mainwnd__rpane__set_data_wrapper },
    { "app.good_time_to_deliver_news", &_C_app__good_time_to_deliver_news_wrapper },
    { "update", &_C_update_wrapper },
    { "app.failed_to_start", &_C_app__failed_to_start_wrapper },
    { "mainwnd.set_connection_status", &_C_mainwnd__set_connection_status_wrapper },
    { "mainwnd.set_change_count", &_C_mainwnd__set_change_count_wrapper },
    { "workspace.set_monitoring_enabled", &_C_workspace__set_monitoring_enabled_wrapper },
    { "app.request_model", &_C_app__request_model_wrapper },
    { "project.path_of_best_file_matching_path_suffix", &C_project__path_of_best_file_matching_path_suffix },
    { NULL, NULL }
};

msg_func_t find_msg_handler(const char *api_name) {
    for (msg_entry_t *entry = entries; entry->api_name; entry++) {
        if (0 == strcmp(api_name, entry->api_name))
            return entry->func;
    }
    return NULL;
}
