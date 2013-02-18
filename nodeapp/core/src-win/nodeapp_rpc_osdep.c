
#include "nodeapp.h"

#include <process.h>

static HANDLE nodeapp_stdin_fd = NULL, nodeapp_stdout_fd = NULL;
static HANDLE nodeapp_process = NULL;
static volatile bool nodeapp_is_shut_down = false;

static void nodeapp_rpc_thread(void *dummy);
static void nodeapp_rpc_launch();

void nodeapp_rpc_startup() {
    _beginthread(nodeapp_rpc_thread, 0, NULL);
}

void nodeapp_rpc_shutdown() {
    nodeapp_is_shut_down = true;
    CloseHandle(nodeapp_stdin_fd);
    CloseHandle(nodeapp_stdout_fd);
    DWORD result = WaitForSingleObject(nodeapp_process, 2000);
    if (result != WAIT_OBJECT_0) {
        TerminateProcess(nodeapp_process, 42);
    }
    CloseHandle(nodeapp_process);
}

void nodeapp_rpc_send_raw(const char *line) {
    fprintf(stderr, "app:  Sending: %s", line);
    DWORD len = strlen(line);
    while (len > 0) {
        DWORD written = 0;
        BOOL success = WriteFile(nodeapp_stdin_fd, line, len, &written, NULL);
        if (!success)
            break;
        line += written;
        len  -= written;
    }
}

static void nodeapp_rpc_thread(void *dummy) {
    while (!nodeapp_is_shut_down) {
        nodeapp_rpc_launch();
        fprintf(stderr, "app:  Node launched, sending init.\n");
        nodeapp_invoke_on_main_thread(nodeapp_rpc_send_init, NULL);

        time_t startTime = time(NULL);

        char buf[10240];
        while (1) {
            DWORD cb = 0;
            BOOL success = ReadFile(nodeapp_stdout_fd, buf, sizeof(buf), &cb, NULL);
            if (!success)
                break;
            if (cb == 0)
                break;  // end of file
            nodeapp_rpc_received_raw(buf, cb);
        }

        if (!nodeapp_is_shut_down) {
            CloseHandle(nodeapp_stdin_fd);
            CloseHandle(nodeapp_stdout_fd);
            DWORD result = WaitForSingleObject(nodeapp_process, 2000);
            if (result != WAIT_OBJECT_0) {
                TerminateProcess(nodeapp_process, 42);
            }
            CloseHandle(nodeapp_process);
        }

        time_t endTime = time(NULL);
        if (endTime < startTime + 3) {
            // shut down in less than 3 seconds considered a crash
            nodeapp_is_shut_down = true;
            nodeapp_invoke_on_main_thread((INVOKE_LATER_FUNC)nodeapp_emergency_shutdown_backend_crashed, NULL);
        }
        fprintf(stderr, "app:  Node terminated.\n");
    }
}

// The following code is based off of KB190351
static void nodeapp_rpc_launch() {
    HANDLE hChildStdinRd, hChildStdinWr, hChildStdoutRd, hChildStdoutWr;
    BOOL fSuccess;

    SECURITY_ATTRIBUTES saAttr;
    saAttr.nLength = sizeof(SECURITY_ATTRIBUTES);
    saAttr.bInheritHandle = TRUE;
    saAttr.lpSecurityDescriptor = NULL;

    fSuccess = CreatePipe(&hChildStdinRd, &hChildStdinWr, &saAttr, 0);
    assert(fSuccess);
    // make a non-inheritable duplicate and close the original (otherwise it gets inherited and we wouldn't be able to close it)
    fSuccess = DuplicateHandle(GetCurrentProcess(), hChildStdinWr, GetCurrentProcess(), &nodeapp_stdin_fd, 0, FALSE, DUPLICATE_SAME_ACCESS);
    assert(fSuccess);
    CloseHandle(hChildStdinWr);

    fSuccess = CreatePipe(&hChildStdoutRd, &hChildStdoutWr, &saAttr, 0);
    assert(fSuccess);
    fSuccess = DuplicateHandle(GetCurrentProcess(), hChildStdoutRd, GetCurrentProcess(), &nodeapp_stdout_fd, 0, FALSE, DUPLICATE_SAME_ACCESS);
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

    char *cmd_line = str_printf("\"%s\" \"%s\"", nodeapp_bundled_nodeapp_path, nodeapp_bundled_backend_js);
    wchar_t *pszCmdLine = U2W(cmd_line);
    free(cmd_line);

    PROCESS_INFORMATION piProcInfo;
    fSuccess = CreateProcess(NULL, pszCmdLine, NULL, NULL, TRUE, 0, NULL, NULL, &siStartInfo, &piProcInfo);
    assert(fSuccess);

    CloseHandle(piProcInfo.hThread);
    nodeapp_process = piProcInfo.hProcess;
    // piProcInfo.dwProcessId;

    // if we don't close these, ReadFile won't signal end-of-file (and will hang forever)
    CloseHandle(hChildStdinRd);
    CloseHandle(hChildStdoutWr);
}
