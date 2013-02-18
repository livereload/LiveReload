#include "nodeapp_ui_element_osdep_generic.hh"
#include "nodeapp_ui_element_osdep_utils.hh"


GenericViewUIElement::GenericViewUIElement(UIElement *parent_context, const char *_id, id view) : ViewUIElement(parent_context, _id, view, [ViewUIElementDelegate class]) {
}


GenericControlUIElement::GenericControlUIElement(UIElement *parent_context, const char *_id, id view) : ControlUIElement(parent_context, _id, view, [ViewUIElementDelegate class]) {
}
