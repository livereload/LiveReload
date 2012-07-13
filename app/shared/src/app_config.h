#ifndef app_config_h
#define app_config_h

#define NODEAPP_NODE_BINARY "node"
#define NODEAPP_NODE_BINARY_OVERRIDE_ENVVAR "LRNodeOverride"

#define NODEAPP_BACKEND_JS "backend/bin/livereload-backend.js"
#define NODEAPP_BACKEND_JS_OVERRIDE_ENVVAR "LRBackendOverride"

#define NODEAPP_APPDATA_FOLDER "LiveReload"

#define NODEAPP_LOG_SUBFOLDER "Logs"
#define NODEAPP_LOG_FILE      "log.txt"

#define NODEAPP_BACKENDCRASH_TITLE           "LiveReload Crash"
#define NODEAPP_BACKENDCRASH_TEXT            "My backend has decided to be very naughty, so looks like I have to crash.\n\nGeeky details: %s"
#define NODEAPP_BACKENDCRASH_BUTTON_QUIT     "Just Quit"
#define NODEAPP_BACKENDCRASH_BUTTON_HELP     "Troubleshooting Instructions"
#ifdef __APPLE__
#define NODEAPP_BACKENDCRASH_BUTTON_HELP_URL "http://help.livereload.com/kb/troubleshooting/livereload-has-crashed-on-a-mac"
#else
#define NODEAPP_BACKENDCRASH_BUTTON_HELP_URL "http://help.livereload.com/kb/troubleshooting/livereload-has-crashed-on-windows"
#endif

#define NODEAPP_LICENSING_SAVED_RECEIPTS_FOLDER "Receipts"
#define NODEAPP_LICENSING_SAVED_RECEIPTS_EXT    "livereload-receipt"

#endif
