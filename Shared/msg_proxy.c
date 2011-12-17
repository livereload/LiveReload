#include "msg_proxy.h"
#include "nodeapi.h"


void S_app_init(json_t *data) {
    node_send("app.init", data);
}

void S_log_omg(json_t *data) {
    node_send("log.omg", data);
}

void S_log_wtf(json_t *data) {
    node_send("log.wtf", data);
}

void S_log_fyi(json_t *data) {
    node_send("log.fyi", data);
}

void S_preferences_init(json_t *data) {
    node_send("preferences.init", data);
}

void S_preferences_set_default(json_t *data) {
    node_send("preferences.setDefault", data);
}

void S_preferences_set(json_t *data) {
    node_send("preferences.set", data);
}

void S_preferences_get(json_t *data) {
    node_send("preferences.get", data);
}

void S_projects_init(json_t *data) {
    node_send("projects.init", data);
}

void S_projects_update_project_list(json_t *data) {
    node_send("projects.updateProjectList", data);
}

void S_projects_add(json_t *data) {
    node_send("projects.add", data);
}

void S_projects_remove(json_t *data) {
    node_send("projects.remove", data);
}

void S_projects_change_detected(json_t *data) {
    node_send("projects.changeDetected", data);
}

void S_rpc_init(json_t *data) {
    node_send("rpc.init", data);
}

void S_rpc_send(json_t *data) {
    node_send("rpc.send", data);
}

void S_rpc_execute(json_t *data) {
    node_send("rpc.execute", data);
}

void S_websockets_init(json_t *data) {
    node_send("websockets.init", data);
}

void S_websockets_send_reload_command(json_t *data) {
    node_send("websockets.sendReloadCommand", data);
}
