#ifndef nodeapp_ui_element_osdep_application_hh
#define nodeapp_ui_element_osdep_application_hh

#include "nodeapp_ui_element.hh"
#include "nodeapp_ui_objcobject.hh"


class ApplicationUIElement : public RootUIElement {
public:
    ApplicationUIElement();

protected:
    virtual UIElement *create_child(const char *name, json_t *payload);
    virtual bool invoke_custom_func(const char *method, json_t *arg);
};

#endif
