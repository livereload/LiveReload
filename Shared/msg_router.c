#include "msg_router.h"
#include <stddef.h>
#include <string.h>

typedef struct {
    const char   *api_name;
    msg_func_t    func;
} msg_entry_t;

void C_mainwnd__set_project_list(json_t *data);

msg_entry_t entries[] = {
    { "mainwnd.set_project_list", &C_mainwnd__set_project_list },
    { NULL, NULL }
};

msg_func_t find_msg_handler(const char *api_name) {
    for (msg_entry_t *entry = entries; entry->api_name; entry++) {
        if (0 == strcmp(api_name, entry->api_name))
            return entry->func;
    }
    return NULL;
}
