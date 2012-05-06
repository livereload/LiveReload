#ifndef nodeapp_ui_element_osdep_textfield_hh
#define nodeapp_ui_element_osdep_textfield_hh

#include "nodeapp_ui_element_osdep_control.hh"
#include "nodeapp_ui_objcobject.hh"


class TextFieldUIElement : public ControlUIElement {
public:
    TextFieldUIElement(UIElement *parent_context, const char *_id, id view);
protected:
    virtual bool set(const char *property, json_t *value);
    virtual void pre_set(json_t *payload);
};


@interface TextFieldUIElementDelegate : ViewUIElementDelegate <NSTextFieldDelegate>
@end


#endif
