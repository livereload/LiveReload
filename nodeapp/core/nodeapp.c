
#include "nodeapp_private.h"

void nodeapp_init() {
    nodeapp_compute_paths();
    nodeapp_init_logging();
    nodeapp_rpc_startup();
}

void nodeapp_shutdown() {
    nodeapp_rpc_shutdown();
}
