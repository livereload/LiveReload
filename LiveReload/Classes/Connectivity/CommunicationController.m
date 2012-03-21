
#import "msg_proxy.h"

#import "Project.h"
#import "Preferences.h"
#import "Stats.h"

#include "communication.h"
#include "sglib.h"


void comm_broadcast_reload_requests(reload_session_t *session) {
    Project *project = (Project *)session->project;

    NSLog(@"Broadcasting change in %@", project.path);
    
    SGLIB_SORTED_LIST_MAP_ON_ELEMENTS(reload_request_t, session->first, request, next, {
        json_t *arg = json_object();
        json_object_set_new(arg, "path", json_string(request->path));
        json_object_set_new(arg, "originalPath", json_string(request->original_path ?: ""));
        json_object_set_new(arg, "liveCSS", !project.disableLiveRefresh ? json_true() : json_false());
        json_object_set_new(arg, "enableOverride", project.enableRemoteServerWorkflow ? json_true() : json_false());
        S_websockets_send_reload_command(arg);
    });
}
