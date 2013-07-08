
#include "nodeapp.h"

void nodeapp_rpc_send_init(void *dummy) {
    json_t *data = json_object();
    json_object_set_new(data, "resourcesDir", json_string(nodeapp_bundled_resources_dir));
    json_object_set_new(data, "appDataDir", json_string(nodeapp_appdata_dir));
    json_object_set_new(data, "logDir", json_string(nodeapp_log_dir));
    json_object_set_new(data, "logFile", json_string(nodeapp_log_file));
    json_object_set_new(data, "version", json_string(NODEAPP_VERSION));
#if defined(APPSTORE)
    json_object_set_new(data, "build", json_string("appstore"));
#else
    json_object_set_new(data, "build", json_string("trial"));
#endif
#if defined(__APPLE__)
    json_object_set_new(data, "platform", json_string("mac"));
#else
    json_object_set_new(data, "platform", json_string("windows"));
#endif

    nodeapp_rpc_send("app.init", data);

    json_t *message = json_object();
    json_object_set_new(message, "service", json_string("server"));
    json_object_set_new(message, "command", json_string("init"));
    json_object_set_new(message, "appVersion", json_string(NODEAPP_VERSION));
    nodeapp_rpc_send_json(message);
}
