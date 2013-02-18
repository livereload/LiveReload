#include "nodeapp_ui_element_osdep_button.hh"
#include "nodeapp_ui_element_osdep_utils.hh"


ButtonUIElement::ButtonUIElement(UIElement *parent_context, const char *_id, id view) : ControlUIElement(parent_context, _id, view, [ButtonUIElementDelegate class]) {
    [view_ setTarget:self()];
    [view_ setAction:@selector(perform:)];
}

bool ButtonUIElement::set(const char *property, json_t *value) {
    if (0 == strcmp(property, "state")) {
        if (json_is_true(value))
            [view_ setState:NSOnState];
        else if (json_is_false(value))
            [view_ setState:NSOffState];
        else if (json_is_string(value) && 0 == strcmp("mixed", json_string_value(value)))
            [view_ setState:NSMixedState];
        else
            assert1(json_is_string(value), "Unsupported value for 'state' property of %s", path_);
        return true;
    } else {
        return ControlUIElement::set(property, value);
    }
}


@implementation ButtonUIElementDelegate

#define that ObjCObject::from_id<ButtonUIElement>(self)

- (IBAction)perform:(id)sender {
    json_t *state;
    if ([that->view_ state] == NSOnState)
        state = json_true();
    else if ([that->view_ state] == NSOffState)
        state = json_false();
    else
        state = json_string("mixed");
    that->notify(json_object_1("clicked", state));
}

@end
