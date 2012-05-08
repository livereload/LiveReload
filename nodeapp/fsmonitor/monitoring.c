
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
    json_t *tree;
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
    if (change->tree)
        json_object_set_new(arg, "tree", change->tree);
    if (change->diff)
        json_object_set_new(arg, "changes", change->diff);
    S_monitoring_change_detected(arg);

    free(change);
}

json_t *fstree_to_json(fstree_t *tree) {
    int count = fstree_count(tree);
    json_t *items[count];
    json_t *items_children[count];

    for (int i = 0; i < count; ++i) {
        json_t *item = items[i] = json_object();

        fstree_item_type type;
        int parent_index;
        long size, time_sec, time_nsec;
        const char *name = fstree_get(tree, i, &parent_index, &type, &size, &time_sec, &time_nsec);

        json_object_set_new(item, "name", json_string(name));
        json_object_set_new(item, "type", json_string(fstree_item_type_name(type)));
        json_object_set_new(item, "size", json_integer(size));
        json_object_set_new(item, "mtime", json_integer(time_sec));

        items_children[i] = NULL;

        if (i > 0) {
            assert(parent_index >= 0);
            assert(parent_index < i);

            json_t *parent_children = items_children[parent_index];
            if (!parent_children) {
                parent_children = items_children[parent_index] = json_array();
                json_object_set_new(items[parent_index], "children", parent_children);
            }
            json_array_append_new(parent_children, item);
        }
    }

    return items[0];
}

json_t *fsdiff_to_json(fsdiff_t *diff) {
    json_t *json = json_array();
    int count = fsdiff_count(diff);
    for (int i = 0; i < count; ++i)
        json_array_append(json, json_string(fsdiff_get(diff, i)));
    fsdiff_free(diff);
    return json;
}

static void fsmonitor_callback(fsdiff_t *diff, fstree_t *tree, void *data) {
    item_t *item = (item_t *)data;

    change_t *change = (change_t *)malloc(sizeof(change_t));
    change->id = json_incref(item->id);

    if (diff) {
        change->diff = fsdiff_to_json(diff);
        change->tree = NULL;
    } else {
        change->diff = NULL;
        change->tree = fstree_to_json(tree);
    }

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

void nodeapp_fsmonitor_reset() {
    for (int i = 0; i < cmonitors; ++i)
        if (monitors[i].id != NULL)
            item_free(&monitors[i]);
    cmonitors = 0;
    nextid = 0;
}
