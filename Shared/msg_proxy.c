#include "msg_proxy.h"
#include "nodeapi.h"


void S_app_init(json_t *data) {
    node_send("app.init", data);
}

void S_app_ping(json_t *data) {
    node_send("app.ping", data);
}

void S_websockets_send_reload_command(json_t *data) {
    node_send("websockets.sendReloadCommand", data);
}
