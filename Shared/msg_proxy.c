#include "msg_proxy.h"
#include "nodeapi.h"


void S_app_init(json_t *data) {
    node_send("app.init", data);
}

void S_projects_update_project_list(json_t *data) {
    node_send("projects.updateProjectList", data);
}

void S_projects_add(json_t *data) {
    node_send("projects.add", data);
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
