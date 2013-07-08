
#include "nodeapp_private.h"

#include "strbuffer.h"
#include "nodeapp_rpc_router.h"

#include <assert.h>
#include <time.h>

static char nodeapp_rpc_receive_buf[1024 * 1024];

//static void nodeapp_rpc_send_ping(void *dummy) {
//    nodeapp_rpc_send("{ \"hello, node\": 42 }\n");
//
//    dispatch_after_f(dispatch_time(DISPATCH_TIME_NOW, 1.0 * NSEC_PER_SEC), dispatch_get_main_queue(), NULL, nodeapp_rpc_send_ping);
//}

static void nodeapp_rpc_received_line(char *line) {
    fprintf(stderr, "app:  Received: '%s'\n", line);

    json_error_t error;
    json_t *incoming = json_loads(line, 0, &error);
    if (!incoming) {
        fprintf(stderr,  "app:  Cannot parse received line as JSON: '%s'\n", line);
        free(line);
        return;
    }
    const char *service = json_string_value(json_object_get(incoming, "service"));
    const char *command = json_string_value(json_object_get(incoming, "command"));
    if (!service)
        return;

    assert(command);

    char *full_name = str_printf("%s.%s", service, command);

    msg_func_t handler = find_msg_handler(full_name);
    if (handler == NULL) {
        fprintf(stderr,  "\n**************************************\napp:  Unknown command received: '%s'\n**************************************\n\n", full_name);
//        abort();
//        exit(1);
    } else {
        json_t *response = handler(incoming);
        if (json_array_size(incoming) > 2) {
            json_t *response_command = json_array_get(incoming, 2);
            json_t *array = json_array();
            json_array_append(array, response_command);
            if (response)
                json_array_append_new(array, response);
            else
                json_array_append_new(array, json_null());
            nodeapp_rpc_send_json(array);
        } else {
            if (response)
                json_decref(response);
        }
    }

    json_decref(incoming);
    free(full_name);
    free(line);
}

void nodeapp_rpc_received_raw(char *buf, int cb) {
    strncat(nodeapp_rpc_receive_buf, buf, cb);

    char *start = nodeapp_rpc_receive_buf;
    char *end;
    while ((end = (char *)strchr(start, '\n')) != NULL) {
        *end = 0;
        nodeapp_invoke_on_main_thread((INVOKE_LATER_FUNC)nodeapp_rpc_received_line, strdup(start));
        start = end + 1;
    }
    if (start > nodeapp_rpc_receive_buf) {
        // strings overlap, so can't use strcpy
        memmove(nodeapp_rpc_receive_buf, start, strlen(start) + 1);
    }
}

static int dump_to_strbuffer(const char *buffer, size_t size, void *data) {
    return strbuffer_append_bytes((strbuffer_t *)data, buffer, size);
}

void nodeapp_rpc_send_json(json_t *array) {
    strbuffer_t strbuff;
    int rv = strbuffer_init(&strbuff);
    assert(rv == 0);

    if (0 == json_dump_callback(array, dump_to_strbuffer, (void *)&strbuff, 0)) {
        strbuffer_append(&strbuff, "\n");
        nodeapp_rpc_send_raw(strbuffer_value(&strbuff));
    }

    strbuffer_close(&strbuff);

    json_decref(array);
}

void nodeapp_rpc_send(const char *command, json_t *json) {
    json_t *array = json_array();
    json_array_append_new(array, json_string(command));
    json_array_append_new(array, json);

//    nodeapp_rpc_send_json(array);

    strbuffer_t strbuff;
    int rv = strbuffer_init(&strbuff);
    assert(rv == 0);

    if (0 == json_dump_callback(array, dump_to_strbuffer, (void *)&strbuff, 0)) {
        strbuffer_append(&strbuff, "\n");
        fprintf(stderr, "App ignoring send: %s\n", strbuffer_value(&strbuff));
    }

    strbuffer_close(&strbuff);
    json_decref(array);
}
