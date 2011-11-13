
#ifndef LiveReload_EventBus_h
#define LiveReload_EventBus_h

// compared by identity, could be void *, declared as char * to aid debugging
typedef const char *event_name_t;

typedef void (*event_handler_t)(event_name_t event, void *data, void *context);

void eventbus_post(event_name_t event, void *data);
void eventbus_subscribe(event_name_t event, event_handler_t handler, void *context);
void eventbus_unsubscribe(event_name_t event, event_handler_t handler, void *context);

#define EVENTBUS_DECLARE_EVENT(event) extern const char *const event
#define EVENTBUS_DEFINE_EVENT(event) const char *const event = #event

#endif
