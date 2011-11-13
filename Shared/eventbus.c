
#include "EventBus.h" 

#include <stddef.h>
#include <assert.h>


typedef struct {
    event_name_t event;
    event_handler_t handler;
    void *context;
} event_subscription_t;

#define MaxSubscriptions 1000

static event_subscription_t subscriptions[MaxSubscriptions] = { {NULL, NULL, NULL} };

#define for_each_subscription(cur) for (event_subscription_t *cur = subscriptions, *end = cur + MaxSubscriptions; cur < end; ++cur)



void eventbus_post(event_name_t event, void *data) {
    assert(event);
    for_each_subscription(cur) {
        if (cur->handler && (cur->event == event || cur->event == NULL)) {
            cur->handler(event, data, cur->context);
        }
    }
}

void eventbus_subscribe(event_name_t event, event_handler_t handler, void *context) {
    assert(handler);
    for_each_subscription(cur) {
        if (cur->event == NULL && cur->handler == NULL) {
            cur->event = event;
            cur->handler = handler;
            cur->context = context;
            return;
        }
    }
    assert(0); // out of subscriptions
}

void eventbus_unsubscribe(event_name_t event, event_handler_t handler, void *context) {
    assert(handler);
    for_each_subscription(cur) {
        if (cur->event == event && cur->handler == handler && cur->context == context) {
            cur->event = NULL;
            cur->handler = NULL;
            cur->context = NULL;
            return;
        }
    }
}
