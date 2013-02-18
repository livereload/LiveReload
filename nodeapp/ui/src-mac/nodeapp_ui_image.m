
#include "nodeapp_ui.h"
#include "hashtable.h"

static bool initialized = false;
static hashtable_t shared_images;

void nodeapp_ui_image_init() {
    if (initialized)
        return;
    initialized = true;
    hashtable_init(&shared_images, jsonp_hash_str, jsonp_str_equal, NULL, NULL);
}

void nodeapp_ui_image_register(const char *name, NSImage *image) {
    nodeapp_ui_image_init();
    hashtable_set(&shared_images, strdup(name), [image retain]);
}

NSImage *nodeapp_ui_image_lookup(const char *name) {
    nodeapp_ui_image_init();
    return (NSImage *)hashtable_get(&shared_images, name);
}
