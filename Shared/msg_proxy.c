#include "msg_proxy.h"
#include "nodeapi.h"


void S_app_init(json_t *data) {
    node_send("app.init", data);
}

void S_app_ping(json_t *data) {
    node_send("app.ping", data);
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
