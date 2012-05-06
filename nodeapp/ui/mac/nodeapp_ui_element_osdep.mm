#include "nodeapp_ui_element.hh"
#include "nodeapp_ui_element_osdep_application.hh"


UIElement *UIElement::create_root_context() {
    return new ApplicationUIElement();
}
