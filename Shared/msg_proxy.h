#ifndef LIVERELOAD_MSG_PROXY_H_INCLUDED
#define LIVERELOAD_MSG_PROXY_H_INCLUDED

#include "jansson.h"

void S_app_init(json_t *data);
void S_log_warn(json_t *data);
void S_preferences_init(json_t *data);
void S_preferences_set_default(json_t *data);
void S_preferences_set(json_t *data);
void S_preferences_get(json_t *data);
void S_projects_init(json_t *data);
void S_projects_update_project_list(json_t *data);
void S_projects_add(json_t *data);
void S_projects_remove(json_t *data);
void S_projects_change_detected(json_t *data);
void S_rpc_init(json_t *data);
void S_rpc_send(json_t *data);
void S_rpc_execute(json_t *data);

#endif
