
#include "common.h"
#include "project.h"
#include "kvec.h"
#include "reload_request.h"
#include "fsmonitor.h"

#include <stdlib.h>
#include <string.h>


typedef struct project_t {
    char *path;
    bool compilation_enabled;
    bool live_refresh_enabled;
    fsmonitor_t *monitor;
    struct reload_session_t *_session;
} project_t;


kvec_t(project_t *) projects;


int project_count() {
  return kv_size(projects);
}

project_t *project_get(int index) {
  return kv_A(projects, index);
}

void project_add_new(const char *path) {
  project_t *project = project_create(path,  NULL);
  project->monitor = fsmonitor_create(path);
  kv_push(project_t *, projects, project);
}


project_t *project_create(const char *path, json_t *memento) {
  project_t *project = (project_t *) calloc(1, sizeof(project_t));
  project->path = strdup(path);
  return project;
}

void project_free(project_t *project) {
  free(project->path);
  free(project);
}

const char *project_name(project_t *project) {
    return basename(project->path);
}

char *project_display_path(project_t *project) {
  return project->path;
}

