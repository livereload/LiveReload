
#include "nodeapp_broker.h"

#import <Cocoa/Cocoa.h>

json_t *C_ui__create_window(json_t *arg) {
    NSString *className = json_nsstring_value(json_object_get(arg, "class"));
    NSString *controllerClassName = [NSString stringWithFormat:@"%@Controller", className];
    Class klass = NSClassFromString(controllerClassName);
    NSCAssert(klass, @"Invalid class name: %@", controllerClassName);
    
    NSWindowController *windowController = [[[klass alloc] init] autorelease];
    return json_broker_object_retained(windowController);
}

void C_ui__show_window(json_t *arg) {
    NSWindowController *windowController = json_broker_object_value(json_object_get(arg, "window"));
    [windowController showWindow:nil];
}
