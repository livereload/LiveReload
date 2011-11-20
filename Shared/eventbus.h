
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
#define EVENTBUS_OBJC_HANDLER(klass, the_event, method) \
    void klass##_##the_event(event_name_t event, void *data, void *context) { \
        [(klass *)context method]; \
    }
#define EVENTBUS_OBJC_SUBSCRIBE(klass, event) eventbus_subscribe(event, klass##_##event, self)
#define EVENTBUS_OBJC_UNSUBSCRIBE(klass, event) eventbus_unsubscribe(event, klass##_##event, self)

#endif
