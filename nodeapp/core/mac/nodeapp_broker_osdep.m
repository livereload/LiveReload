#include "nodeapp_broker.h"

#include <objc/runtime.h>



////////////////////////////////////////////////////////////////////////////////
#pragma mark - Private APIs

static void nodeapp_broker_unexpose(nodeapp_broker_obj_id_t obj_id);



////////////////////////////////////////////////////////////////////////////////
#pragma mark - NodeAppBrokerDisposeHandler

static double nodeapp_broker_dummy = 42.42;
#define nodeapp_broker_assoc_key (&nodeapp_broker_dummy)

@interface NodeAppBrokerDisposeHandler : NSObject {
@public
    nodeapp_broker_obj_id_t obj_id;
}
@end
@implementation NodeAppBrokerDisposeHandler
- (void)dealloc {
    nodeapp_broker_unexpose(obj_id);
    [super dealloc];
}
@end



////////////////////////////////////////////////////////////////////////////////
#pragma mark - Global variables

BOOL                     initialized   = NO;
CFMutableDictionaryRef   refs          = NULL;
CFMutableDictionaryRef   strong_refs   = NULL;
nodeapp_broker_obj_id_t  next_id       = 1;



////////////////////////////////////////////////////////////////////////////////
#pragma mark - Initialization

#define nodeapp_broker_intro() if (initialized); else nodeapp_broker_initialize()

void nodeapp_broker_initialize() {
    refs = CFDictionaryCreateMutable(NULL, 100, NULL, NULL);
    strong_refs = CFDictionaryCreateMutable(NULL, 100, NULL, &kCFTypeDictionaryValueCallBacks);
    initialized = YES;
}



////////////////////////////////////////////////////////////////////////////////
#pragma mark - Mapping between objects and ids

id nodeapp_broker_resolve(nodeapp_broker_obj_id_t obj_id) {
    return (const void *) CFDictionaryGetValue(refs, (const void *)obj_id);
}

nodeapp_broker_obj_id_t nodeapp_broker_obj_id(id object) {
    NodeAppBrokerDisposeHandler *handler = objc_getAssociatedObject(object, nodeapp_broker_assoc_key);
    if (handler)
        return handler->obj_id;
    else
        return 0;
}

nodeapp_broker_obj_id_t nodeapp_broker_expose(id object) {
    if (!object)
        return 0;

    nodeapp_broker_intro();

    nodeapp_broker_obj_id_t obj_id = nodeapp_broker_obj_id(object);
    if (obj_id)
        return obj_id;

    obj_id = next_id++;
    CFDictionarySetValue(refs, (const void *)obj_id, object);

    NodeAppBrokerDisposeHandler *handler = [[NodeAppBrokerDisposeHandler alloc] init];
    handler->obj_id = obj_id;
    objc_setAssociatedObject(object, nodeapp_broker_assoc_key, handler, OBJC_ASSOCIATION_RETAIN);
    [handler release];

    return obj_id;
}

static void nodeapp_broker_unexpose(nodeapp_broker_obj_id_t obj_id) {
    nodeapp_broker_unretain(obj_id);
    CFDictionaryRemoveValue(refs, (const void *)obj_id);
}



////////////////////////////////////////////////////////////////////////////////
#pragma mark - Retaining

nodeapp_broker_obj_id_t nodeapp_broker_retain(nodeapp_broker_obj_id_t obj_id) {
    if (!obj_id)
        return 0;
    id object = nodeapp_broker_resolve(obj_id);
    if (object) {
        CFDictionarySetValue(strong_refs, (const void *)obj_id, object);
    }
    return obj_id;
}

void nodeapp_broker_unretain(nodeapp_broker_obj_id_t obj_id) {
    if (!obj_id)
        return;
    CFDictionaryRemoveValue(strong_refs, (const void *)obj_id);
}



////////////////////////////////////////////////////////////////////////////////
#pragma mark - JSON helpers

id json_broker_object_value(json_t *obj_id_json) {
    return nodeapp_broker_resolve(json_broker_obj_id_value(obj_id_json));
}

json_t *json_broker_object(id object) {
    return json_broker_obj_id(nodeapp_broker_expose(object));
}

json_t *json_broker_object_retained(id object) {
    return json_broker_obj_id(nodeapp_broker_retain(nodeapp_broker_expose(object)));
}

json_t *nodeapp_objc_to_json_with_broker(id value) {
    if (value == nil) {
        return json_null();
    } else if ([value isKindOfClass:[NSString class]]) {
        return json_string([value UTF8String]);
    } else if ([value isKindOfClass:[NSNumber class]]) {
        double d = [value doubleValue];
        if (fabs(d - floor(d)) < 1e-10) {
            return json_integer([value intValue]);
        } else {
            return json_real(d);
        }
    } else if ([value isKindOfClass:[NSArray class]]) {
        int count = [value count];
        json_t *result = json_array();
        for (int i = 0; i < count; ++i)
            json_array_append_new(result, nodeapp_objc_to_json_with_broker([value objectAtIndex:i]));
        return result;
    } else if ([value isKindOfClass:[NSDictionary class]]) {
        json_t *result = json_object();
        for (id key in value) {
            if ([key isKindOfClass:[NSNumber class]])
                key = [key description];
            NSCAssert([key isKindOfClass:[NSString class]], @"Cannot convert a non-string key to JSON");
            json_object_set_new(result, [key UTF8String], nodeapp_objc_to_json_with_broker([value objectForKey:key]));
        }
        return result;
    } else {
        return json_broker_object(value);
    }
}
