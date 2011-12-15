#ifndef LiveReload_routing_table_h
#define LiveReload_routing_table_h

#include "jansson.h"

typedef void (*msg_func_t)(json_t *data);

msg_func_t find_msg_handler(const char *api_name);

#endif
