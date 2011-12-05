
#include "common.h"
#include "nodeapi.h"
#include "stringutil.h"
#include "osdep.h"

#include "strbuffer.h"

#include <dispatch/dispatch.h>

#include <sys/param.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <sys/select.h>

#include <signal.h>
#include <errno.h>
#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <paths.h>
#include <pthread.h>
#include <assert.h>


int node_stdin_fd, node_stdout_fd;
int node_pid = 0;
const char *node_bundled_backend_js;
char node_buf[1024 * 1024];


static void *node_thread(void *dummy);
//static void node_send_ping(void *dummy);


void node_init() {
    node_bundled_backend_js = str_printf("%s/backend/lib/livereload-backend.js", os_bundled_resources_path);

    pthread_t thread;
    pthread_create(&thread, NULL, node_thread, NULL);

//    dispatch_after_f(dispatch_time(DISPATCH_TIME_NOW, 1.0 * NSEC_PER_SEC), dispatch_get_main_queue(), NULL, node_send_ping);
}

void node_shutdown() {
    if (node_pid) {
        kill(node_pid, SIGINT);
    }
}


//static void node_send_ping(void *dummy) {
//    node_send("{ \"hello, node\": 42 }\n");
//
//    dispatch_after_f(dispatch_time(DISPATCH_TIME_NOW, 1.0 * NSEC_PER_SEC), dispatch_get_main_queue(), NULL, node_send_ping);
//}

void handle_hello() {
}

void node_received(char *line) {
    fprintf(stderr, "Received from node: '%s'\n", line);

    json_error_t error;
    json_t *incoming = json_loads(line, 0, &error);
    const char *command = json_string_value(json_array_get(incoming, 0));
    json_t *args = json_array_get(incoming, 1);

    if (!command)
        args;
    else if (0 == strcmp(command, "hello"))
        handle_hello();

    json_decref(incoming);
    free(line);
}

void node_send_raw(const char *line) {
    fprintf(stderr, "Sending to node: %s", line);
    write(node_stdin_fd, line, strlen(line));
}

static int dump_to_strbuffer(const char *buffer, size_t size, void *data) {
    return strbuffer_append_bytes((strbuffer_t *)data, buffer, size);
}

void node_send(const char *command, json_t *json) {
    json_t *array = json_array();
    json_array_append_new(array, json_string(command));
    json_array_append_new(array, json);

    strbuffer_t strbuff;
    int rv = strbuffer_init(&strbuff);
    assert(rv == 0);

    if (0 == json_dump_callback(array, dump_to_strbuffer, (void *)&strbuff, 0)) {
        strbuffer_append(&strbuff, "\n");
        node_send_raw(strbuffer_value(&strbuff));
    }

    strbuffer_close(&strbuff);

    json_decref(array);
}

void node_send_init(void *dummy) {
    json_t *plugin_paths = json_array();
    json_array_append_new(plugin_paths, json_string(os_bundled_resources_path));

    json_t *data = json_object();
    json_object_set_new(data, "pluginFolders", plugin_paths);

    node_send("init", data);
}


static void *node_thread(void *dummy) {
    int pipe_stdin[2], pipe_stdout[2];
    int result;

restart_node:

    result = pipe(pipe_stdin);
    assert(result == 0);
    result = pipe(pipe_stdout);
    assert(result == 0);

    int pid = fork();
    assert(pid >= 0);

    if (pid == 0) {
        if (pipe_stdin[0] != STDIN_FILENO) {
            dup2(pipe_stdin[0], STDIN_FILENO);
            close(pipe_stdin[0]);
        }
        close(pipe_stdin[1]);

        if (pipe_stdout[1] != STDOUT_FILENO) {
            dup2(pipe_stdout[1], STDOUT_FILENO);
            close(pipe_stdout[1]);
        }
        close(pipe_stdout[0]);

        write(STDOUT_FILENO, "Hello!\n", strlen("Hello!\n"));

        execl(os_bundled_node_path, "node", node_bundled_backend_js, NULL);
        _exit(127);
    }
    node_pid = pid;

    invoke_on_main_thread(node_send_init, NULL);

    close(pipe_stdin[0]);
    node_stdin_fd = pipe_stdin[1];

    close(pipe_stdout[1]);
    node_stdout_fd = pipe_stdout[0];

    // cool! now time to actually do something...

    fd_set pristine_read_fds, read_fds;

    FD_ZERO(&pristine_read_fds);
    FD_SET(node_stdout_fd, &pristine_read_fds);
    int max_fd = node_stdout_fd + 1;

    char buf[10240];
    while (1) {
        int rv;
        do {
            read_fds  = pristine_read_fds;
            rv = select(max_fd, &read_fds, NULL, NULL, NULL);
        } while (rv == EINTR);
        if (rv < 0) {
            perror("select");
            assert(0);
        }

        if (FD_ISSET(node_stdout_fd, &read_fds)) {
            int cb = read(node_stdout_fd, buf, sizeof(buf));
            if (cb < 0) {
                break;
            }
            strncat(node_buf, buf, cb);

            char *start = buf;
            char *end;
            while ((end = (char *)strchr(start, '\n')) != NULL) {
                *end = 0;
                invoke_on_main_thread((INVOKE_LATER_FUNC)node_received, strdup(start));
                start = end + 1;
            }
            if (start > buf) {
                // strings overlap, so can't use strcpy
                memmove(buf, start, strlen(start) + 1);
            }
        }
    }

    int exit_status, rv;
    do {
        rv = waitpid(pid, &exit_status, 0);
    } while (rv == -1 && errno == EINTR);

    close(node_stdin_fd);
    close(node_stdout_fd);

    goto restart_node;
}
