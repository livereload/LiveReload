#ifndef nodeapp_ui_element_osdep_table_hh
#define nodeapp_ui_element_osdep_table_hh

#include "nodeapp_ui_element_osdep_table_base.hh"
#include "nodeapp_ui_objcobject.hh"


class TableUIElement : public BaseTableUIElement {
public:
    TableUIElement(UIElement *parent_context, const char *_id, id view);
    virtual ~TableUIElement();

    json_t *rows_;
protected:
    virtual void pre_set(json_t *payload);
};


@interface TableUIElementDelegate : ViewUIElementDelegate <NSTableViewDataSource, NSTableViewDelegate>
@end


#endif
