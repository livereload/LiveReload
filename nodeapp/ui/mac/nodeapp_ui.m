
#include "nodeapp_broker.h"

#import <Cocoa/Cocoa.h>
#include <objc/runtime.h>


@interface NodeAppBinding : NSObject

- (id)initWithCallbackId:(NSString *)callbackId;

@end

@implementation NodeAppBinding {
    NSString *_callbackId;
}

- (id)initWithCallbackId:(NSString *)callbackId {
    self = [super init];
    if (self) {
        _callbackId = [callbackId copy];
    }
    return self;
}

- (void)dealloc {
    [_callbackId release];
    [super dealloc];
}

- (void)performSomething:(id)sender {
    nodeapp_rpc_send([_callbackId UTF8String], json_null());
}

@end


id nodeapp_ui_get(id parent, NSString *path) {
    if ([path isEqualToString:@"window"])
        return parent;
    else
        return [parent valueForKeyPath:path];
}

void nodeapp_ui_bind_control_action(id control, json_t *callback) {
    id binding = [[[NodeAppBinding alloc] initWithCallbackId:json_nsstring_value(callback)] autorelease];
    [control setTarget:binding];
    [control setAction:@selector(performSomething:)];
    objc_setAssociatedObject(control, [NodeAppBinding class], binding, OBJC_ASSOCIATION_RETAIN);
}

void nodeapp_ui_bind(id control, json_t *bindings) {
    for (void *iter = json_object_iter(bindings); iter; iter = json_object_iter_next(bindings, iter)) {
        const char *event = json_object_iter_key(iter);
        json_t *arg = json_object_iter_value(iter);
        
        if ([control isKindOfClass:[NSControl class]]) {
            if (0 == strcmp(event, "click")) {
                nodeapp_ui_bind_control_action(control, arg);
            }
        }
    }
}

void nodeapp_ui_bind_children(id parent, json_t *bindings, json_t *response) {
    for (void *iter = json_object_iter(bindings); iter; iter = json_object_iter_next(bindings, iter)) {
        const char *key = json_object_iter_key(iter);
        json_t *subbindings = json_object_iter_value(iter);
        
        id child = nodeapp_ui_get(parent, NSStr(key));
        if (child) {
            json_object_set(response, key, json_broker_object(child));
            nodeapp_ui_bind(child, subbindings);
        }
    }
}

json_t *C_ui__create_window(json_t *arg) {
    NSString *className = json_nsstring_value(json_object_get(arg, "className"));
    NSString *controllerClassName = [NSString stringWithFormat:@"%@Controller", className];
    Class klass = NSClassFromString(controllerClassName);
    NSCAssert(klass, @"Invalid class name: %@", controllerClassName);
    
    NSWindowController *windowController = [[[klass alloc] init] autorelease];
    
    json_t *response = json_object();
    json_object_set(response, "window", json_broker_object_retained(windowController));

    [windowController window]; // load before binding
    nodeapp_ui_bind_children(windowController, json_object_get(arg, "bindings"), response);
    
    return response;
}

void C_ui__show_window(json_t *arg) {
    NSWindowController *windowController = json_broker_object_value(json_object_get(arg, "window"));
    [windowController showWindow:nil];
}
