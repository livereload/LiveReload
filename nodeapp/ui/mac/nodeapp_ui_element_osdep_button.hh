#ifndef nodeapp_ui_element_osdep_button_hh
#define nodeapp_ui_element_osdep_button_hh

#include "nodeapp_ui_element_osdep_control.hh"
#include "nodeapp_ui_objcobject.hh"


class ButtonUIElement : public ControlUIElement {
public:
    ButtonUIElement(UIElement *parent_context, const char *_id, id view);
protected:
    virtual bool set(const char *property, json_t *value);
};


@interface ButtonUIElementDelegate : ViewUIElementDelegate <NSTextFieldDelegate>

- (IBAction)perform:(id)sender;

@end


#endif
