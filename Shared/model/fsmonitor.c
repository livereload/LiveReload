
#include "common.h"
#include "fsmonitor.h"
#include "fstree.h"

#include <malloc.h>
#include <string.h>
#include <assert.h>
#include <stdio.h>

#ifdef _MSC_VER
#include <windows.h>
#include <process.h>
#endif


EVENTBUS_DEFINE_EVENT(fsmonitor_changed_detected_event);

typedef struct fsmonitor_t {
  char *path;
#ifdef _MSC_VER
  HANDLE hThread;
#endif
} fsmonitor_t;


typedef struct {
  SLIST_ENTRY entry;
} foo;

void do_listen(fsmonitor_t *monitor);


fsmonitor_t *fsmonitor_create(const char *path) {
  fsmonitor_t *monitor = (fsmonitor_t *) calloc(1, sizeof(fsmonitor_t));
  monitor->path = strdup(path);
  monitor->hThread = (HANDLE) _beginthread((void(*)(void*))do_listen, 0, monitor);
  printf("Creating initial tree for %s\n", path);
  fstree_t *tree = fstree_create(monitor->path);
  fstree_dump(tree);
  fstree_free(tree);
  return monitor;
}

void fsmonitor_free(fsmonitor_t *monitor) {
  free(monitor->path);
  free(monitor);
}

void fsmonitor_did_detect_change(fsmonitor_t *monitor) {
  printf("YES! Detected change in %s\n", monitor->path);
  fstree_t *tree = fstree_create(monitor->path);
  fstree_dump(tree);
  fstree_free(tree);
}

void do_listen(fsmonitor_t *monitor) {
  HANDLE hChange = FindFirstChangeNotification(U2W(monitor->path), TRUE, FILE_NOTIFY_CHANGE_FILE_NAME | FILE_NOTIFY_CHANGE_DIR_NAME | FILE_NOTIFY_CHANGE_LAST_WRITE | FILE_NOTIFY_CHANGE_SIZE | FILE_NOTIFY_CHANGE_ATTRIBUTES);
  assert(hChange != INVALID_HANDLE_VALUE);
  printf("Listening to changes in %s\n", monitor->path);
  while (TRUE) {
    DWORD status = WaitForMultipleObjects(1, &hChange, FALSE, INFINITE);
    if (status == WAIT_OBJECT_0) {
      printf("Detected change in %s\n", monitor->path);
      invoke_on_main_thread((INVOKE_LATER_FUNC) fsmonitor_did_detect_change, monitor);
      DWORD result = FindNextChangeNotification(hChange);
      assert(result);
    } else {
      assert(!"WaitForMultipleObjects returned error");
    }
  }
}

