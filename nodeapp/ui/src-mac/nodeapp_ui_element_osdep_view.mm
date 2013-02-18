#include "nodeapp_ui_element_osdep_view.hh"
#include "nodeapp_ui_element_osdep_utils.hh"


ViewUIElement::ViewUIElement(UIElement *parent_context, const char *_id, id view, Class delegate_klass) : UIElement(parent_context, _id), ObjCObject(delegate_klass) {
    view_ = [view retain];
}

ViewUIElement::~ViewUIElement() {
    [view_ release];
}

bool ViewUIElement::set(const char *property, json_t *value) {
    if (0 == strcmp(property, "visible")) {
        bool hidden = !json_bool_value(value);
        if ([view_ isHidden] != hidden) {
            [view_ setHidden:hidden];
        }
        return true;
    } else if (0 == strcmp(property, "placeholder")) {
        const char *placeholder = json_string_value(value);
        UIElement *element = parent_context_->resolve_child(placeholder, NULL);
        assert2(element, "Cannot find placeholder element '%s' around %s", placeholder, path_);
        ViewUIElement *viewEl = dynamic_cast<ViewUIElement *>(element);
        assert2(viewEl, "Placeholder element '%s' (around %s) must be a view", placeholder, path_);
        NSView *placeholderView = viewEl->view_;

        if ([view_ superview] != [placeholderView superview]) {
            [view_ removeFromSuperview];
            [[placeholderView superview] addSubview:view_ positioned:NSWindowBelow relativeTo:placeholderView];
        }
        [view_ setFrame:[placeholderView frame]];
        [(NSView *)view_ setAutoresizingMask:[placeholderView autoresizingMask]];
        return true;
    } else {
        return UIElement::set(property, value);
    }
}

bool ViewUIElement::invoke_custom_func(const char *method, json_t *arg) {
    return invoke_custom_func_in_nsobject(view_, method, arg);
}


@implementation ViewUIElementDelegate
@end
