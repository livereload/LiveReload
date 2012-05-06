#ifndef nodeapp_ui_element_osdep_generic_hh
#define nodeapp_ui_element_osdep_generic_hh

#include "nodeapp_ui_element_osdep_view.hh"
#include "nodeapp_ui_element_osdep_control.hh"
#include "nodeapp_ui_objcobject.hh"


class GenericViewUIElement : public ViewUIElement {
public:
    GenericViewUIElement(UIElement *parent_context, const char *_id, id view);
};


class GenericControlUIElement : public ControlUIElement {
public:
    GenericControlUIElement(UIElement *parent_context, const char *_id, id view);
};


#endif
