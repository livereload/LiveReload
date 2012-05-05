#ifndef nodeapp_private_h
#define nodeapp_private_h

#include "nodeapp.h"

void nodeapp_emergency_shutdown_backend_crashed();

void nodeapp_compute_paths();
void nodeapp_compute_paths_osdep();

void nodeapp_rpc_startup();
void nodeapp_rpc_shutdown();
void nodeapp_rpc_received_raw(char *buf, int cb);
void nodeapp_rpc_send_raw(const char *line);
void nodeapp_rpc_send_init(void *dummy);

void nodeapp_init_logging();

void nodeapp_autorelease_pool_activate();
void nodeapp_autorelease_cleanup();

#endif
