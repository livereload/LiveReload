#include "nodeapp_ui_element_osdep_application.hh"
#include "nodeapp_ui_element_osdep_utils.hh"
#include "nodeapp_ui_element_osdep_window.hh"


ApplicationUIElement::ApplicationUIElement() : RootUIElement("#application") {
}

UIElement *ApplicationUIElement::create_child(const char *name, json_t *payload) {
    NSString *className = json_nsstring_value(json_object_get(payload, "type"));
    assert(className && "New window payload must specify a 'type'");

    NSString *controllerClassName = [NSString stringWithFormat:@"%@Controller", className];
    Class klass = NSClassFromString(controllerClassName);
    assert(klass && "Window controller class not found for the specified window type");

    NSWindowController *windowController = [[[klass alloc] initWithWindowNibName:className] autorelease];
    return new WindowUIElement(this, name, windowController);
}

bool ApplicationUIElement::invoke_custom_func(const char *method, json_t *arg) {
    return invoke_custom_func_in_nsobject([NSApp delegate], method, arg);
}
