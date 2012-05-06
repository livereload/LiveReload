#ifndef nodeapp_ui_element_osdep_control_hh
#define nodeapp_ui_element_osdep_control_hh

#include "nodeapp_ui_element_osdep_view.hh"
#include "nodeapp_ui_objcobject.hh"


class ControlUIElement : public ViewUIElement {
public:
    ControlUIElement(UIElement *parent_context, const char *_id, id view, Class delegate_klass);
protected:
    virtual bool set(const char *property, json_t *value);
};


#endif
