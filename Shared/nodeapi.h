
#ifndef LiveReload_nodeapi_h
#define LiveReload_nodeapi_h

#include "jansson.h"

void node_init();
void node_shutdown();

void node_send(const char *command, json_t *json);

#endif
