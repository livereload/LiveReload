
#include "common.h"
#include "nodeapi.h"
#include "stringutil.h"
#include "osdep.h"
#include "jansson.h"
#include "strbuffer.h"
#include "msg_router.h"
#include "version.h"

#include <assert.h>
#include <time.h>

const char *node_bundled_backend_js;
volatile bool node_shut_down = false;

void node_received_raw(char *buf, int cb);
void node_send_raw(const char *line);
void node_send_json(json_t *array);
void node_send_init(void *dummy);
char node_buf[1024 * 1024];

#ifdef WIN32

#include <windows.h>
#include <process.h>

HANDLE node_stdin_fd, node_stdout_fd;
HANDLE node_process = NULL;

static void node_thread(void *dummy);
static void node_launch();

void node_init() {
    node_bundled_backend_js = str_printf("%s/bin/livereload-backend.js", os_bundled_backend_path);
    _beginthread(node_thread, 0, NULL);
}

void node_shutdown() {
    node_shut_down = true;
    CloseHandle(node_stdin_fd);
    CloseHandle(node_stdout_fd);
    DWORD result = WaitForSingleObject(node_process, 2000);
    if (result != WAIT_OBJECT_0) {
        TerminateProcess(node_process, 42);
    }
    CloseHandle(node_process);
}

void node_send_raw(const char *line) {
    fprintf(stderr, "app:  Sending: %s", line);
    DWORD len = strlen(line);
    while (len > 0) {
        DWORD written = 0;
        BOOL success = WriteFile(node_stdin_fd, line, len, &written, NULL);
        if (!success)
            break;
        line += written;
        len  -= written;
    }
}

static void node_thread(void *dummy) {
    while (!node_shut_down) {
        node_launch();
        fprintf(stderr, "app:  Node launched, sending init.\n");
        invoke_on_main_thread(node_send_init, NULL);

        time_t startTime = time(NULL);

        char buf[10240];
        while (1) {
            DWORD cb = 0;
            BOOL success = ReadFile(node_stdout_fd, buf, sizeof(buf), &cb, NULL);
            if (!success)
                break;
            if (cb == 0)
                break;  // end of file
            node_received_raw(buf, cb);
        }

        if (!node_shut_down) {
            CloseHandle(node_stdin_fd);
            CloseHandle(node_stdout_fd);
            DWORD result = WaitForSingleObject(node_process, 2000);
            if (result != WAIT_OBJECT_0) {
                TerminateProcess(node_process, 42);
            }
            CloseHandle(node_process);
        }

        time_t endTime = time(NULL);
        if (endTime < startTime + 3) {
            // shut down in less than 3 seconds considered a crash
            node_shut_down = true;
            invoke_on_main_thread((INVOKE_LATER_FUNC)os_emergency_shutdown_backend_crashed, NULL);
        }
        fprintf(stderr, "app:  Node terminated.\n");
    }
}

// The following code is based off of KB190351
static void node_launch() {
    HANDLE hChildStdinRd, hChildStdinWr, hChildStdoutRd, hChildStdoutWr;
    BOOL fSuccess;

    SECURITY_ATTRIBUTES saAttr;
    saAttr.nLength = sizeof(SECURITY_ATTRIBUTES);
    saAttr.bInheritHandle = TRUE;
    saAttr.lpSecurityDescriptor = NULL;

    fSuccess = CreatePipe(&hChildStdinRd, &hChildStdinWr, &saAttr, 0);
    assert(fSuccess);
    // make a non-inheritable duplicate and close the original (otherwise it gets inherited and we wouldn't be able to close it)
    fSuccess = DuplicateHandle(GetCurrentProcess(), hChildStdinWr, GetCurrentProcess(), &node_stdin_fd, 0, FALSE, DUPLICATE_SAME_ACCESS);
    assert(fSuccess);
    CloseHandle(hChildStdinWr);

    fSuccess = CreatePipe(&hChildStdoutRd, &hChildStdoutWr, &saAttr, 0);
    assert(fSuccess);
    fSuccess = DuplicateHandle(GetCurrentProcess(), hChildStdoutRd, GetCurrentProcess(), &node_stdout_fd, 0, FALSE, DUPLICATE_SAME_ACCESS);
    assert(fSuccess);
    CloseHandle(hChildStdoutRd);

    STARTUPINFO siStartInfo;
    ZeroMemory(&siStartInfo, sizeof(STARTUPINFO));
    siStartInfo.cb = sizeof(STARTUPINFO);
    siStartInfo.dwFlags     = STARTF_USESTDHANDLES | STARTF_USESHOWWINDOW;
    siStartInfo.hStdInput   = hChildStdinRd;
    siStartInfo.hStdOutput  = hChildStdoutWr;
    siStartInfo.hStdError   = GetStdHandle(STD_ERROR_HANDLE);
    siStartInfo.wShowWindow = SW_HIDE;

    char *cmd_line = str_printf("\"%s\" \"%s\"", os_bundled_node_path, node_bundled_backend_js);
    wchar_t *pszCmdLine = U2W(cmd_line);
    free(cmd_line);

    PROCESS_INFORMATION piProcInfo;
    fSuccess = CreateProcess(NULL, pszCmdLine, NULL, NULL, TRUE, 0, NULL, NULL, &siStartInfo, &piProcInfo);
    assert(fSuccess);

    CloseHandle(piProcInfo.hThread);
    node_process = piProcInfo.hProcess;
    // piProcInfo.dwProcessId;

    // if we don't close these, ReadFile won't signal end-of-file (and will hang forever)
    CloseHandle(hChildStdinRd);
    CloseHandle(hChildStdoutWr);
}

#else

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


static void *node_thread(void *dummy);
//static void node_send_ping(void *dummy);


void node_init() {
    node_bundled_backend_js = str_printf("%s/bin/livereload-backend.js", os_bundled_backend_path);

    pthread_t thread;
    pthread_create(&thread, NULL, node_thread, NULL);

//    dispatch_after_f(dispatch_time(DISPATCH_TIME_NOW, 1.0 * NSEC_PER_SEC), dispatch_get_main_queue(), NULL, node_send_ping);
}

void node_shutdown() {
    node_shut_down = true;
    if (node_pid) {
        kill(node_pid, SIGINT);
    }
}

void node_send_raw(const char *line) {
    fprintf(stderr, "app:  Sending: %s", line);
    write(node_stdin_fd, line, strlen(line));
}

static void *node_thread(void *dummy) {
    int pipe_stdin[2], pipe_stdout[2];
    int result;
    time_t start_time;

restart_node:

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
            if (cb <= 0) {
                break;
            }
            node_received_raw(buf, cb);
        }
    }

    int exit_status, rv;
    do {
        rv = waitpid(pid, &exit_status, 0);
    } while (rv == -1 && errno == EINTR);

    close(node_stdin_fd);
    close(node_stdout_fd);

    time_t end_time = time(NULL);
    if (end_time < start_time + 3) {
        // shut down in less than 3 seconds considered a crash
        node_shut_down = true;
        invoke_on_main_thread((INVOKE_LATER_FUNC)os_emergency_shutdown_backend_crashed, NULL);
    }
    fprintf(stderr, "app:  Node terminated.\n");

    if (!node_shut_down)
        goto restart_node;
    return NULL;
}
#endif


//static void node_send_ping(void *dummy) {
//    node_send("{ \"hello, node\": 42 }\n");
//
//    dispatch_after_f(dispatch_time(DISPATCH_TIME_NOW, 1.0 * NSEC_PER_SEC), dispatch_get_main_queue(), NULL, node_send_ping);
//}

void node_received(char *line) {
    fprintf(stderr, "app:  Received: '%s'\n", line);

    json_error_t error;
    json_t *incoming = json_loads(line, 0, &error);
    if (!incoming) {
        fprintf(stderr,  "app:  Cannot parse received line as JSON: '%s'\n", line);
        free(line);
        return;
    }
    const char *command = json_string_value(json_array_get(incoming, 0));
    assert(command);
    json_t *arg = json_array_get(incoming, 1);

    msg_func_t handler = find_msg_handler(command);
    if (handler == NULL) {
        fprintf(stderr,  "app:  Unknown command received: '%s'", command);
        exit(1);
    } else {
        json_t *response = handler(arg);
        if (json_array_size(incoming) > 2) {
            json_t *response_command = json_array_get(incoming, 2);
            json_t *array = json_array();
            json_array_append(array, response_command);
            if (response)
                json_array_append_new(array, response);
            else
                json_array_append_new(array, json_null());
            node_send_json(array);
        } else {
            if (response)
                json_decref(response);
        }
    }

    json_decref(incoming);
    free(line);
}

void node_received_raw(char *buf, int cb) {
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

static int dump_to_strbuffer(const char *buffer, size_t size, void *data) {
    return strbuffer_append_bytes((strbuffer_t *)data, buffer, size);
}

void node_send_json(json_t *array) {
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

void node_send(const char *command, json_t *json) {
    json_t *array = json_array();
    json_array_append_new(array, json_string(command));
    json_array_append_new(array, json);
    node_send_json(array);
}

void node_send_init(void *dummy) {
    json_t *plugin_paths = json_array();
    json_array_append_new(plugin_paths, json_string(os_bundled_resources_path));

    json_t *data = json_object();
    json_object_set_new(data, "pluginFolders", plugin_paths);
    json_object_set_new(data, "preferencesFolder", json_string(os_preferences_path));
    json_object_set_new(data, "version", json_string(LIVERELOAD_VERSION));

    node_send("app.init", data);
}
