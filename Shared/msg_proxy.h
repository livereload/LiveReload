#ifndef LIVERELOAD_MSG_PROXY_H_INCLUDED
#define LIVERELOAD_MSG_PROXY_H_INCLUDED

#include "jansson.h"

void S_app_init(json_t *data);
void S_app_ping(json_t *data);
void S_websockets_send_reload_command(json_t *data);

#endif
