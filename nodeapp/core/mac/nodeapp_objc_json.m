
#include "nodeapp.h"

json_t *objc_to_json(id value) {
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
            json_array_append_new(result, objc_to_json([value objectAtIndex:i]));
        return result;
    } else if ([value isKindOfClass:[NSDictionary class]]) {
        json_t *result = json_object();
        for (id key in value) {
            if ([key isKindOfClass:[NSNumber class]])
                key = [key description];
            NSCAssert([key isKindOfClass:[NSString class]], @"Cannot convert a non-string key to JSON");
            json_object_set_new(result, [key UTF8String], objc_to_json([value objectForKey:key]));
        }
        return result;
    } else {
        NSCAssert(NO, @"Cannot convert this type to JSON: %@", [[value class] description]);
        return NULL;
    }
}
