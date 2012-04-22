
#include "nodeapp.h"
#include "nodeapp_rpc_proxy.h"

#include "fsmonitor.h"

#include "jansson.h"
#include <assert.h>

#define MAX_ITEMS 100

typedef struct {
    json_t *id;
    fsmonitor_t *monitor;
} item_t;

item_t monitors[MAX_ITEMS];
int cmonitors = 0;
int nextid = 1;

typedef struct {
    json_t *id;
    json_t *diff;
} change_t;

item_t *find_free_item() {
    for (int i = 0; i < cmonitors; ++i)
        if (monitors[i].id == NULL)
            return &monitors[i];
    if (cmonitors < MAX_ITEMS)
        return &monitors[cmonitors++];
    assert(!"No more monitors available");
    abort();
    return NULL;
}

item_t *find_item(json_t *id) {
    for (int i = 0; i < cmonitors; ++i)
        if (json_equal(monitors[i].id, id))
            return &monitors[i];
    return NULL;
}

void item_free(item_t *item) {
    fsmonitor_free(item->monitor);
    json_decref(item->id);
    item->id = NULL;
}

static void fsmonitor_callback_main_thread(void *data) {
    change_t *change = (change_t *)data;

    json_t *arg = json_object();
    json_object_set_new(arg, "id", change->id);
    json_object_set_new(arg, "changes", change->diff);
    S_projects_change_detected(arg);

    free(change);
}

static void fsmonitor_callback(fsdiff_t *diff, void *data) {
    item_t *item = (item_t *)data;

    json_t *json = json_array();
    int count = fsdiff_count(diff);
    for (int i = 0; i < count; ++i)
        json_array_append(json, json_string(fsdiff_get(diff, i)));
    fsdiff_free(diff);

    change_t *change = (change_t *)malloc(sizeof(change_t));
    change->id = json_incref(item->id);
    change->diff = json;
    nodeapp_invoke_on_main_thread(fsmonitor_callback_main_thread, change);
}

void C_monitoring__add(json_t *arg) {
    json_t *id = json_object_get(arg, "id");
    if (!id)
        return;
    const char *path = json_string_value(json_object_get(arg, "path"));
    assert(path);

    item_t *item = find_item(id);
    assert(!item);

    item = find_free_item();
    item->id = json_incref(id);
    item->monitor = fsmonitor_create(path, NULL, fsmonitor_callback, item);
}

json_t *C_monitoring__remove(json_t *arg) {
    json_t *id = json_object_get(arg, "id");
    if (!id)
        return NULL;
    item_t *item = find_item(id);
    if (!item)
        return NULL;
    item_free(item);
    return json_true();
}
