
#include "common.h"
#include "sglib.h"
#include "console.h"
#include "stringutil.h"
#include "reload_request.h"

#include <stdlib.h>
#include <string.h>


reload_request_t *reload_request_create(const char *path, const char *original_path) {
    reload_request_t *request = malloc(sizeof(reload_request_t));
    request->path = strdup(path);
    request->original_path = (original_path ? strdup(original_path) : 0);
    request->next = NULL;
    return request;
}

void reload_request_free(reload_request_t *request) {
    free(request->path);
    if (request->original_path)
        free(request->original_path);
    free(request);
}

#define reload_session_comparator(x, y) strcmp(x->path, y->path)

const char *live_extensions[] = { ".css", ".png", ".jpg", ".gif" };

bool project_can_refresh_live(void *project, const char *path) {
    // TODO: plugin support some day
    ARRAY_FOREACH(const char *, live_extensions, pext, {
        if (str_ends_with(path, *pext))
            return true;
    });
    return false;
}

reload_session_t *reload_session_create(void *project) {
    reload_session_t *session = malloc(sizeof(reload_session_t));
    session->first = NULL;
    session->project = project;
    return session;
}

void reload_session_add(reload_session_t *session, reload_request_t *request) {
    reload_request_t *result;
    SGLIB_SORTED_LIST_ADD_IF_NOT_MEMBER(reload_request_t, session->first, request, reload_session_comparator, next, result);
    if (result) {
        reload_request_free(request);
    }
}

void reload_session_clear(reload_session_t *session) {
    SGLIB_SORTED_LIST_MAP_ON_ELEMENTS(reload_request_t, session->first, request, next, reload_request_free(request););
    session->first = NULL;
}

void reload_session_free(reload_session_t *session) {
    reload_session_clear(session);
    free(session);
}

bool reload_session_empty(reload_session_t *session) {
    return !session->first;
}

bool reload_session_can_refresh_live(reload_session_t *session) {
    SGLIB_SORTED_LIST_MAP_ON_ELEMENTS(reload_request_t, session->first, request, next, {
        if (!project_can_refresh_live(session->project, request->path)) {
            return false;
        }
    });
    return true;
}
