
#include "nodeapp_private.h"

const char *nodeapp_bundled_resources_dir;
const char *nodeapp_bundled_node_path;
const char *nodeapp_bundled_backend_js;
const char *nodeapp_appdata_dir;
const char *nodeapp_log_dir;
const char *nodeapp_log_file;

void nodeapp_compute_paths() {
    nodeapp_compute_paths_osdep();

    nodeapp_bundled_node_path = getenv(NODEAPP_NODE_BINARY_OVERRIDE_ENVVAR);
    if (!nodeapp_bundled_node_path || !*nodeapp_bundled_node_path)
        nodeapp_bundled_node_path = str_printf("%s/%s", nodeapp_bundled_resources_dir, NODEAPP_NODE_BINARY);
    
    nodeapp_bundled_backend_js = getenv(NODEAPP_BACKEND_JS_OVERRIDE_ENVVAR);
    if (!nodeapp_bundled_backend_js || !*nodeapp_bundled_backend_js)
        nodeapp_bundled_backend_js = str_printf("%s/%s", nodeapp_bundled_resources_dir, NODEAPP_BACKEND_JS);
}
