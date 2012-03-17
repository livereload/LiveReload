
#ifndef LiveReload_osdep_h
#define LiveReload_osdep_h

void os_init();
void os_emergency_shutdown_backend_crashed();

extern const char *os_bundled_resources_path;
extern const char *os_bundled_node_path;
extern const char *os_bundled_backend_path;
extern const char *os_preferences_path;
extern const char *os_log_path;

#endif
