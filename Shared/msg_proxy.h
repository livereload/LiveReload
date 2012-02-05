#ifndef LIVERELOAD_MSG_PROXY_H_INCLUDED
#define LIVERELOAD_MSG_PROXY_H_INCLUDED

#include "jansson.h"

void S_app_init(json_t *data);
void S_app_ping(json_t *data);
void S_log_omg(json_t *data);
void S_log_wtf(json_t *data);
void S_log_fyi(json_t *data);
void S_mainwnd_set_selected_project(json_t *data);
void S_plugins_init(json_t *data);
void S_preferences_init(json_t *data);
void S_preferences_set_testing_options(json_t *data);
void S_preferences_set_default(json_t *data);
void S_preferences_set(json_t *data);
void S_preferences_get(json_t *data);
void S_projects_find_by_id(json_t *data);
void S_projects_init(json_t *data);
void S_projects_update_project_list(json_t *data);
void S_projects_add(json_t *data);
void S_projects_remove(json_t *data);
void S_projects_change_detected(json_t *data);
void S_rpc_init(json_t *data);
void S_rpc_exit(json_t *data);
void S_rpc_send(json_t *data);
void S_rpc_execute(json_t *data);
void S_stats_startup(json_t *data);
void S_websockets_init(json_t *data);
void S_websockets_send_reload_command(json_t *data);

#endif
