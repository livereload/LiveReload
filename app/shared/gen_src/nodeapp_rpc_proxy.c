#include "nodeapp.h"
#include "nodeapp_rpc_proxy.h"


void S_app_init(json_t *data) {
    nodeapp_rpc_send("app.init", data);
}

void S_app_ping(json_t *data) {
    nodeapp_rpc_send("app.ping", data);
}

void S_projects_add(json_t *data) {
    nodeapp_rpc_send("projects.add", data);
}

void S_projects_remove(json_t *data) {
    nodeapp_rpc_send("projects.remove", data);
}

void S_projects_change_detected(json_t *data) {
    nodeapp_rpc_send("projects.changeDetected", data);
}

void S_ui_notify(json_t *data) {
    nodeapp_rpc_send("ui.notify", data);
}
