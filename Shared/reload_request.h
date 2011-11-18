
#ifndef LiveReload_reload_request_h
#define LiveReload_reload_request_h

#include <stdbool.h>


typedef struct reload_request_t {
    char *path;
    char *original_path;
    struct reload_request_t *next;
} reload_request_t;

reload_request_t *reload_request_create(const char *path, const char *original_path);
void reload_request_free(reload_request_t *self);


typedef struct reload_session_t {
    void *project;
    reload_request_t *first;
} reload_session_t;

reload_session_t *reload_session_create(void *project);
void reload_session_add(reload_session_t *session, reload_request_t *request);
void reload_session_clear(reload_session_t *session);
void reload_session_free(reload_session_t *session);
bool reload_session_empty(reload_session_t *session);
bool reload_session_can_refresh_live(reload_session_t *session);

#endif
