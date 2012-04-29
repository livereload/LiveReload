
#include "nodeapp_private.h"

// TODO: invent a hook system to avoid referencing modules from core
extern void nodeapp_fsmonitor_reset();
extern void nodeapp_ui_reset();

void nodeapp_init() {
    nodeapp_compute_paths();
    nodeapp_init_logging();
    nodeapp_rpc_startup();
}

void nodeapp_shutdown() {
    nodeapp_rpc_shutdown();
}

void nodeapp_reset() {
    nodeapp_fsmonitor_reset();
    nodeapp_ui_reset();
    nodeapp_init_logging();
}

void nodeapp_rpc_invoke_and_keep_callback(const char *callback, json_t *arg) {
    nodeapp_rpc_send(callback, arg);
}

void nodeapp_rpc_dispose_callback(const char *callback) {
    char *command = str_printf("-%s", callback);
    nodeapp_rpc_send(command, json_null());
    free(command);
}

void nodeapp_rpc_invoke_and_dispose_callback(const char *callback, json_t *arg) {
    nodeapp_rpc_invoke_and_keep_callback(callback, arg);
    nodeapp_rpc_dispose_callback(callback);
}

json_t *json_object_1(const char *key1, json_t *value1) {
    json_t *result = json_object();
    json_object_set_new(result, key1, value1);
    return result;
}

json_t *json_object_2(const char *key1, json_t *value1, const char *key2, json_t *value2) {
    json_t *result = json_object();
    json_object_set_new(result, key1, value1);
    json_object_set_new(result, key2, value2);
    return result;
}
