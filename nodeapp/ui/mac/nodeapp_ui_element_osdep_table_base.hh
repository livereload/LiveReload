#ifndef nodeapp_ui_element_osdep_table_base_hh
#define nodeapp_ui_element_osdep_table_base_hh

#include "nodeapp_ui_element_osdep_control.hh"
#include "nodeapp_ui_objcobject.hh"


class BaseTableUIElement : public ViewUIElement {
public:
    BaseTableUIElement(UIElement *parent_context, const char *_id, id view, Class delegate_klass);
    virtual ~BaseTableUIElement();

    NSString *lookup_id(const char *item_id);
protected:
    NSMutableDictionary *item_ids_;

    virtual bool set(const char *property, json_t *value);
};


@interface BaseTableUIElementDelegate : ViewUIElementDelegate <NSTableViewDataSource, NSTableViewDelegate>
@end


#endif
