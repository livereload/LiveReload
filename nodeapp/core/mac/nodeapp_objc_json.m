
#include "nodeapp.h"

json_t *nodeapp_objc_to_json_or_null(id value) {
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
        for (int i = 0; i < count; ++i) {
            json_t *item = nodeapp_objc_to_json_or_null([value objectAtIndex:i]);
            if (!item) {
                json_decref(result);
                return NULL;
            }

            json_array_append_new(result, item);
        }
        return result;
    } else if ([value isKindOfClass:[NSDictionary class]]) {
        json_t *result = json_object();
        for (id key in value) {
            if ([key isKindOfClass:[NSNumber class]])
                key = [key description];
            NSCAssert([key isKindOfClass:[NSString class]], @"Cannot convert a non-string key to JSON");

            json_t *item = nodeapp_objc_to_json_or_null([value objectForKey:key]);
            if (!item) {
                json_decref(result);
                return NULL;
            }

            json_object_set_new(result, [key UTF8String], item);
        }
        return result;
    } else {
        return NULL;
    }
}

json_t *nodeapp_objc_to_json(id value) {
    json_t *result = nodeapp_objc_to_json_or_null(value);
    if (!result) {
        NSCAssert(NO, @"Cannot convert this type to JSON: %@", [[value class] description]);
        return NULL;
    }
    return result;
}
