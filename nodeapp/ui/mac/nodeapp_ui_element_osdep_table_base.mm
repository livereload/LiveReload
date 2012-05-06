#include "nodeapp_ui_element_osdep_table_base.hh"
#include "nodeapp_ui_element_osdep_utils.hh"


BaseTableUIElement::BaseTableUIElement(UIElement *parent_context, const char *_id, id view, Class delegate_klass) : ViewUIElement(parent_context, _id, view, delegate_klass) {
    item_ids_ = [[NSMutableDictionary alloc] init];
}

BaseTableUIElement::~BaseTableUIElement() {
    [item_ids_ release];
}

NSString *BaseTableUIElement::lookup_id(const char *item_id) {
    NSString *itemId = NSStr(item_id);
    NSString *result = [item_ids_ objectForKey:itemId];
    if (!result) {
        result = itemId;
        [item_ids_ setObject:result forKey:itemId];
    }
    return result;
}

bool BaseTableUIElement::set(const char *property, json_t *value) {
    if (0 == strcmp(property, "dnd-drop-types")) {
        NSMutableArray *array = [NSMutableArray array];
        for_each_array_item(value, i, type_json) {
            const char *type = json_string_value(type_json);
            if (0 == strcmp(type, "file")) {
                [array addObject:NSFilenamesPboardType];
            } else {
                assert2(false, "Unsupported drop type '%s' requested for '%s'", type, path_);
            }
        }
        [view_ registerForDraggedTypes:array];
        return true;
    } else if (0 == strcmp(property, "dnd-drag")) {
        assert1(json_is_true(value), "Unsupported value for dnd-drag for %s", path_);
        [view_ setDraggingSourceOperationMask:NSDragOperationCopy|NSDragOperationLink forLocal:NO];
        return true;
    } else if (0 == strcmp(property, "style")) {
        const char *style = json_string_value(value);
        if (!style) {
            assert1(json_is_string(value), "Unsupported value for style of %s", path_);
        } if (0 == strcmp(style, "regular")) {
            [view_ setSelectionHighlightStyle:NSTableViewSelectionHighlightStyleRegular];
        } else if (0 == strcmp(style, "source-list")) {
            [view_ setSelectionHighlightStyle:NSTableViewSelectionHighlightStyleSourceList];
        } else {
            assert2(json_is_string(value), "Unsupported value '%s' for style of %s", style, path_);
        }
        return true;
    } else if (0 == strcmp(property, "cell-type")) {
        assert1(json_is_string(value), "Unsupported value for cell-type of %s", path_);

        Class klass = NSClassFromString(json_nsstring_value(value));
        assert2(klass, "Cell type '%s' not found for %s'", json_string_value(value), path_);

        NSCell *cell = [[[klass alloc] init] autorelease];
        NSTableColumn *tableColumn = [view_ tableColumnWithIdentifier:@"Name"];
        [cell setEditable:YES];
        [tableColumn setDataCell:cell];

        [view_ reloadData];

        return true;
    } else {
        return ViewUIElement::set(property, value);
    }
}


@implementation BaseTableUIElementDelegate
@end
