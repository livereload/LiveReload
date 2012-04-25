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
json_t *C_app__display_popup_message(json_t *data);
void C_app__reveal_file(json_t *data);
void C_app__open_url(json_t *data);
void C_app__terminate(json_t *data);
json_t *C_preferences__read(json_t *data);
json_t *C_licensing__verify_receipt(json_t *data);
json_t *C_ui__create_window(json_t *data);
void C_ui__show_window(json_t *data);

json_t *_C_broker__unretain_wrapper(json_t *data) {
    C_broker__unretain(data);
    return NULL;
}

json_t *_C_monitoring__add_wrapper(json_t *data) {
    C_monitoring__add(data);
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

json_t *_C_ui__show_window_wrapper(json_t *data) {
    C_ui__show_window(data);
    return NULL;
}

msg_entry_t entries[] = {
    { "broker.unretain", &_C_broker__unretain_wrapper },
    { "monitoring.add", &_C_monitoring__add_wrapper },
    { "monitoring.remove", &C_monitoring__remove },
    { "app.display_popup_message", &C_app__display_popup_message },
    { "app.reveal_file", &_C_app__reveal_file_wrapper },
    { "app.open_url", &_C_app__open_url_wrapper },
    { "app.terminate", &_C_app__terminate_wrapper },
    { "preferences.read", &C_preferences__read },
    { "licensing.verify_receipt", &C_licensing__verify_receipt },
    { "ui.create_window", &C_ui__create_window },
    { "ui.show_window", &_C_ui__show_window_wrapper },
    { NULL, NULL }
};

msg_func_t find_msg_handler(const char *api_name) {
    for (msg_entry_t *entry = entries; entry->api_name; entry++) {
        if (0 == strcmp(api_name, entry->api_name))
            return entry->func;
    }
    return NULL;
}
