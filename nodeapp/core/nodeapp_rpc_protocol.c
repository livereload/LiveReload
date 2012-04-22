
#include "nodeapp.h"

void nodeapp_rpc_send_init(void *dummy) {
    json_t *data = json_object();
    json_object_set_new(data, "resourcesDir", json_string(nodeapp_bundled_resources_dir));
    json_object_set_new(data, "appDataDir", json_string(nodeapp_appdata_dir));
    json_object_set_new(data, "logDir", json_string(nodeapp_log_dir));
    json_object_set_new(data, "version", json_string(NODEAPP_VERSION));
#if defined(APPSTORE)
    json_object_set_new(data, "build", json_string("appstore"));
#else
    json_object_set_new(data, "build", json_string("trial"));
#endif

    nodeapp_rpc_send("app.init", data);
}
