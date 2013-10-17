
#import "Glue.h"

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
    [[Glue glue] handleJsonString:[NSString stringWithUTF8String:line]];
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
