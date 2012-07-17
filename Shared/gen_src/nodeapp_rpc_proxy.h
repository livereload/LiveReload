#ifndef LIVERELOAD_MSG_PROXY_H_INCLUDED
#define LIVERELOAD_MSG_PROXY_H_INCLUDED

#include "jansson.h"

#ifdef __cplusplus
extern "C" {
#endif

void S_app_init(json_t *data);
void S_app_ping(json_t *data);
void S_monitoring_change_detected(json_t *data);
void S_projects_add(json_t *data);
void S_projects_remove(json_t *data);
void S_projects_change_detected(json_t *data);
void S_ui_notify(json_t *data);
void S_websockets_send_reload_command(json_t *data);

#ifdef __cplusplus
}
#endif

#endif
