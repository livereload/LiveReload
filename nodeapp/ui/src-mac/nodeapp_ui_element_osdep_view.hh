#ifndef nodeapp_ui_element_osdep_view_hh
#define nodeapp_ui_element_osdep_view_hh

#include "nodeapp_ui_element.hh"
#include "nodeapp_ui_objcobject.hh"


class ViewUIElement : public UIElement, public ObjCObject {
public:
    ViewUIElement(UIElement *parent_context, const char *_id, id view, Class delegate_klass);
    virtual ~ViewUIElement();

    id view_;
protected:
    virtual bool set(const char *property, json_t *value);
    virtual bool invoke_custom_func(const char *method, json_t *arg);
};


@interface ViewUIElementDelegate : NSObject
@end


#endif
