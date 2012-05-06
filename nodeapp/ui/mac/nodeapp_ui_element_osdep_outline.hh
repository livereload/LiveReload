#ifndef nodeapp_ui_element_osdep_outline_hh
#define nodeapp_ui_element_osdep_outline_hh

#include "nodeapp_ui_element_osdep_control.hh"
#include "nodeapp_ui_objcobject.hh"


class OutlineUIElement : public ViewUIElement {
public:
    OutlineUIElement(UIElement *parent_context, const char *_id, id view);
    virtual ~OutlineUIElement();

    json_t *data_;
    NSString *lookup_id(const char *item_id);
protected:
    NSMutableDictionary *item_ids_;

    virtual bool set(const char *property, json_t *value);
};


@interface OutlineUIElementDelegate : ViewUIElementDelegate <NSOutlineViewDataSource, NSOutlineViewDelegate>
@end


#endif
