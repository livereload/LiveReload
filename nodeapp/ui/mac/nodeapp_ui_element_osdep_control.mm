#include "nodeapp_ui_element_osdep_control.hh"
#include "nodeapp_ui_element_osdep_utils.hh"


ControlUIElement::ControlUIElement(UIElement *parent_context, const char *_id, id view, Class delegate_klass) : ViewUIElement(parent_context, _id, view, delegate_klass) {
}

bool ControlUIElement::set(const char *property, json_t *value) {
    if (0 == strcmp(property, "cell-background-style")) {
        const char *style = json_string_value(value);
        if (!style) {
            assert1(json_is_string(value), "Unsupported value for cell-background-style of %s", path_);
        } if (0 == strcmp(style, "raised")) {
            [[view_ cell] setBackgroundStyle:NSBackgroundStyleRaised];
        } else if (0 == strcmp(style, "lowered")) {
            [[view_ cell] setBackgroundStyle:NSBackgroundStyleLowered];
        } else if (0 == strcmp(style, "light")) {  // the default
            [[view_ cell] setBackgroundStyle:NSBackgroundStyleDark];
        } else if (0 == strcmp(style, "dark")) {
            [[view_ cell] setBackgroundStyle:NSBackgroundStyleLight];
        } else {
            assert2(json_is_string(value), "Unsupported value '%s' for cell-background-style of %s", style, path_);
        }
        return true;
    } else if (0 == strcmp(property, "enabled")) {
        bool enable = json_bool_value(value);
        if ([view_ isEnabled] != enable) {
            [view_ setEnabled:enable];
        }
        return true;
    } else {
        return UIElement::set(property, value);
    }
}
