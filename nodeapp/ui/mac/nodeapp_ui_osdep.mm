
#include "nodeapp_ui.hh"
#include "nodeapp_ui_osdep.hh"

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


ApplicationUIElement::ApplicationUIElement() : RootUIElement("#application") {
}

UIElement *ApplicationUIElement::create_child(const char *name, json_t *payload) {
    NSString *className = json_nsstring_value(json_object_get(payload, "type"));
    assert(className && "New window payload must specify a 'type'");

    NSString *controllerClassName = [NSString stringWithFormat:@"%@Controller", className];
    Class klass = NSClassFromString(controllerClassName);
    assert(klass && "Window controller class not found for the specified window type");

    return new WindowUIElement(this, name, klass);
}


WindowUIElement::WindowUIElement(UIElement *parent_context, const char *id, Class klass) : UIElement(parent_context, id) {
    windowController_ = [[klass alloc] init];
    [windowController_ window]; // load
}

WindowUIElement::~WindowUIElement() {
    [windowController_ release];
}

UIElement *WindowUIElement::create_child(const char *name, json_t *payload) {
    const char *outlet_name = name + 1;
    id view = [windowController_ valueForKey:NSStr(outlet_name)];
    assert2(view, "Cannot find outlet '%s' in window '%s'", outlet_name, path_);
    
    if ([view isKindOfClass:[NSButton class]])
        return new ButtonUIElement(this, name, view);
    else
        return new ViewUIElement(this, name, view);
}

bool WindowUIElement::set(const char *property, json_t *value) {
    if (0 == strcmp(property, "visible")) {
        bool v = json_bool_value(value);
        NSWindow *window = [windowController_ window];
        if ([window isVisible] != v) {
            if (v) {
                [windowController_ showWindow:nil];
            } else {
                [windowController_ close];
            }
        }
        return true;
    }
    return false;
}



ViewUIElement::ViewUIElement(UIElement *parent_context, const char *_id, id view) : UIElement(parent_context, _id) {
    view_ = [view retain];
    delegate_ = new_delegate();
    if (delegate_)
        ((UIElementDelegate *)delegate_)->_element = this;
}

ViewUIElement::~ViewUIElement() {
    [view_ release];
    [delegate_ release];
}

id ViewUIElement::new_delegate() {
    return [[UIElementDelegate alloc] init];
}

void ViewUIElement::hook_action() {
    [view_ setTarget:delegate_];
    [view_ setAction:@selector(perform:)];
}

void ViewUIElement::on_action() {
    notify(json_object_1(action_event_name(), json_true()));
}

const char *ViewUIElement::action_event_name() {
    return "clicked";
}


ButtonUIElement::ButtonUIElement(UIElement *parent_context, const char *_id, id view) : ViewUIElement(parent_context, _id, view) {
    hook_action();
}




UIElement *UIElement::create_root_context() {
    return new ApplicationUIElement();
}


@implementation UIElementDelegate

- (IBAction)perform:(id)sender {
    if (_element)
        _element->on_action();
}

@end

//void nodeapp_ui_bind_children(id parent, json_t *bindings, json_t *response) {
//    for (void *iter = json_object_iter(bindings); iter; iter = json_object_iter_next(bindings, iter)) {
//        const char *key = json_object_iter_key(iter);
//        json_t *subbindings = json_object_iter_value(iter);
//
//        id child = nodeapp_ui_get(parent, NSStr(key));
//        if (child) {
//            json_object_set(response, key, json_broker_object(child));
//            nodeapp_ui_bind(child, subbindings);
//        }
//    }
//}



#define nodeapp_ui_context_intro() if (root_context); else nodeapp_ui_context_init()

//void C_ui__show_window(json_t *arg) {
//    NSWindowController *windowController = json_broker_object_value(json_object_get(arg, "window"));
//    [windowController showWindow:nil];
//}
