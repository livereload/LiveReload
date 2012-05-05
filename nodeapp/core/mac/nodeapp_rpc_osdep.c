
#include "nodeapp_private.h"

#include <dispatch/dispatch.h>

#include <sys/param.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <sys/select.h>

#include <signal.h>
#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <paths.h>
#include <pthread.h>
#include <assert.h>


static int nodeapp_stdin_fd, nodeapp_stdout_fd;
static int nodeapp_pid = 0;
static volatile bool nodeapp_is_shut_down = false;


static void *nodeapp_rpc_thread(void *dummy);
//static void nodeapp_rpc_send_ping(void *dummy);


void nodeapp_rpc_startup() {
    pthread_t thread;
    pthread_create(&thread, NULL, nodeapp_rpc_thread, NULL);

//    dispatch_after_f(dispatch_time(DISPATCH_TIME_NOW, 1.0 * NSEC_PER_SEC), dispatch_get_main_queue(), NULL, nodeapp_rpc_send_ping);
}

void nodeapp_rpc_shutdown() {
    nodeapp_is_shut_down = true;
    if (nodeapp_pid) {
        kill(nodeapp_pid, SIGINT);
    }
}

#define writes(fd, s) write((fd), (s), strlen(s))

void nodeapp_rpc_send_raw(const char *line) {
    fprintf(stderr, "app:  Sending: %s", line);
    write(nodeapp_stdin_fd, line, strlen(line));
}

static void *nodeapp_rpc_thread(void *dummy) {
    int pipe_stdin[2], pipe_stdout[2];
    int result;
    time_t start_time;
    bool developer_mode = false;

restart_node:
    nodeapp_reset();

    start_time = time(NULL);

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

        execl(nodeapp_bundled_node_path, "node", nodeapp_bundled_backend_js, NULL);

        writes(STDOUT_FILENO, "Failed to launch: ");
        writes(STDOUT_FILENO, nodeapp_bundled_node_path);
        writes(STDOUT_FILENO, " ");
        writes(STDOUT_FILENO, nodeapp_bundled_backend_js);
        writes(STDOUT_FILENO, "\n");

        _exit(127);
    }
    nodeapp_pid = pid;

    nodeapp_invoke_on_main_thread(nodeapp_rpc_send_init, NULL);

    close(pipe_stdin[0]);
    nodeapp_stdin_fd = pipe_stdin[1];

    close(pipe_stdout[1]);
    nodeapp_stdout_fd = pipe_stdout[0];

    // cool! now time to actually do something...

    fd_set pristine_read_fds, read_fds;

    FD_ZERO(&pristine_read_fds);
    FD_SET(nodeapp_stdout_fd, &pristine_read_fds);
    int max_fd = nodeapp_stdout_fd + 1;

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

        if (FD_ISSET(nodeapp_stdout_fd, &read_fds)) {
            int cb = read(nodeapp_stdout_fd, buf, sizeof(buf));
            if (cb <= 0) {
                break;
            }
            nodeapp_rpc_received_raw(buf, cb);
        }
    }

    int exit_status, rv;
    do {
        rv = waitpid(pid, &exit_status, 0);
    } while (rv == -1 && errno == EINTR);

    close(nodeapp_stdin_fd);
    close(nodeapp_stdout_fd);
    
    if (WIFEXITED(exit_status) && WEXITSTATUS(exit_status) == 49) {
        // 49 means the backend wants to be restarted
        developer_mode = true; // activate; no way to reset without restarting the whole app
        if (!nodeapp_is_shut_down)
            goto restart_node;
    }

    time_t end_time = time(NULL);
    if (true || end_time < start_time + 3) {
        // shut down in less than 3 seconds considered a crash

        if (developer_mode) {
            // the developer is in the middle of doing some changes; wait a few seconds and try again
            nodeapp_reset(); // kill the UI to provide a visual clue to the developer
            sleep(3);
            goto restart_node;
        }

        nodeapp_is_shut_down = true;
        nodeapp_invoke_on_main_thread((INVOKE_LATER_FUNC)nodeapp_emergency_shutdown_backend_crashed, NULL);
    }
    fprintf(stderr, "app:  Node terminated.\n");

    if (!nodeapp_is_shut_down)
        goto restart_node;
    return NULL;
}
