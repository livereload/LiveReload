
#include "nodeapp.h"

#import <Cocoa/Cocoa.h>

json_t *C_preferences__read(json_t *arg) {
    const char *name = json_string_value(json_object_get(arg, "key"));
    id value = [[NSUserDefaults standardUserDefaults] objectForKey:[NSString stringWithUTF8String:name]];
    return objc_to_json(value);
}
