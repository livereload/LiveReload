#ifndef nodeapp_ui_element_osdep_outline_hh
#define nodeapp_ui_element_osdep_outline_hh

#include "nodeapp_ui_element_osdep_table_base.hh"
#include "nodeapp_ui_objcobject.hh"


class OutlineUIElement : public BaseTableUIElement {
public:
    OutlineUIElement(UIElement *parent_context, const char *_id, id view);
    virtual ~OutlineUIElement();

    json_t *data_;
protected:
    virtual bool set(const char *property, json_t *value);
};


@interface OutlineUIElementDelegate : BaseTableUIElementDelegate <NSOutlineViewDataSource, NSOutlineViewDelegate>
@end


#endif
