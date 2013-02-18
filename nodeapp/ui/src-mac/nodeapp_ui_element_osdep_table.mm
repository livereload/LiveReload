#include "nodeapp_ui_element_osdep_table.hh"
#include "nodeapp_ui_element_osdep_utils.hh"
#include "nodeapp_ui.h"


TableUIElement::TableUIElement(UIElement *parent_context, const char *_id, id view) : BaseTableUIElement(parent_context, _id, view, [TableUIElementDelegate class]) {
    rows_ = json_array();
    
    // data_ must be set before setting data source
    [view_ setDataSource:self()];
    [view_ setDelegate:self()];
}

TableUIElement::~TableUIElement() {
    json_decref(rows_);
}

void TableUIElement::pre_set(json_t *payload) {
    if (json_t *value = json_object_extract(payload, "rows")) {
        json_set(rows_, value);
        for_each_array_item(rows_, index, row_data) {
            assert2(!!json_object_get(row_data, "id"), "Missing id for table row %d of table %s", (int)index, path_);
        }
        [view_ reloadData];
    }
    BaseTableUIElement::pre_set(payload);
}


@implementation TableUIElementDelegate

#define that ObjCObject::from_id<TableUIElement>(self)

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return json_array_size(that->rows_);
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    const char *col_name = [tableColumn.identifier UTF8String];
    json_t *row_data = json_array_get(that->rows_, row);
    json_t *value = json_object_get(row_data, col_name);
    return json_nsstring_value(value);
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification {
    NSInteger rowIndex = [that->view_ selectedRow];
    json_t *rowId;
    if (rowIndex >= 0) {
        json_t *row_data = json_array_get(that->rows_, rowIndex);
        rowId = json_incref(json_object_get(row_data, "id"));
    } else {
        rowId = json_null();
    }
    that->notify(json_object_1("selectedRow", rowId));
}

@end
