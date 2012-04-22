#ifndef LIVERELOAD_MSG_PROXY_H_INCLUDED
#define LIVERELOAD_MSG_PROXY_H_INCLUDED

#include "jansson.h"

void S_app_init(json_t *data);
void S_app_ping(json_t *data);
void S_projects_add(json_t *data);
void S_projects_remove(json_t *data);
void S_projects_change_detected(json_t *data);

#endif
