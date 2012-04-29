
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

id nodeapp_json_to_objc(json_t *json, BOOL null_ok) {
    if (json_is_null(json))
        if (null_ok)
            return NULL;
        else
            return [NSNull null];
    else if (json_is_string(json))
        return json_nsstring_value(json);
    else if (json_is_integer(json))
        return [NSNumber numberWithInt:json_integer_value(json)];
    else if (json_is_real(json))
        return [NSNumber numberWithDouble:json_real_value(json)];
    else if (json_is_true(json))
        return [NSNumber numberWithBool:YES];
    else if (json_is_false(json))
        return [NSNumber numberWithBool:NO];
    else if (json_is_array(json)) {
        size_t len = json_array_size(json);
        id elements[len];
        for (size_t i = 0; i < len; ++i) {
            elements[i] = nodeapp_json_to_objc(json_array_get(json, i), NO);
        }
        return [NSArray arrayWithObjects:elements count:len];
    } else if (json_is_object(json)) {
        size_t len = json_object_size(json);
        id<NSCopying> keys[len];
        id values[len];
        size_t i = 0;
        
        for_each_object_key_value(json, key, value) {
            keys[i] = NSStr(key);
            values[i] = nodeapp_json_to_objc(value, NO);
            ++i;
        }
        
        return [NSDictionary dictionaryWithObjects:values forKeys:keys count:len];
    } else {
        NSCAssert(NO, @"Unknown json type encountered.");
        abort();
    }
}
