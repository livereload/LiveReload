#include "nodeapp_ui.h"
#include "nodeapp_ui_element_osdep_outline.hh"
#include "nodeapp_ui_element_osdep_utils.hh"


OutlineUIElement::OutlineUIElement(UIElement *parent_context, const char *_id, id view) : BaseTableUIElement(parent_context, _id, view, [OutlineUIElementDelegate class]) {
    data_ = json_object_1("#root", json_object_1("children", json_array()));

    // data_ must be set before setting data source
    [view_ setDataSource:self()];
    [view_ setDelegate:self()];
}

OutlineUIElement::~OutlineUIElement() {
    json_decref(data_);
}

bool OutlineUIElement::set(const char *property, json_t *value) {
    if (0 == strcmp(property, "data")) {
        json_set(data_, value);
        [view_ reloadData];
        for_each_object_key_value(data_, item_id, item_data) {
            json_t *j = json_object_get(item_data, "expanded");
            if (j) {
                bool expanded = json_bool_value(j);
                if ([view_ isItemExpanded:lookup_id(item_id)] != expanded) {
                    if (expanded)
                        [view_ expandItem:lookup_id(item_id)];
                    else
                        [view_ collapseItem:lookup_id(item_id)];
                }
            }
        }
        return true;
    } else {
        return BaseTableUIElement::set(property, value);
    }
}


@implementation OutlineUIElementDelegate

#define that ObjCObject::from_id<OutlineUIElement>(self)

- (json_t *)data {
    return that->data_;
}

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item {
    json_t *data = [self data];
    const char *key = (item == nil ? "#root" : [item UTF8String]);
    json_t *item_data = json_object_get(data, key);
    json_t *item_children = json_object_get(item_data, "children");
    return json_array_size(item_children);
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item {
    json_t *data = [self data];
    const char *key = (item == nil ? "#root" : [item UTF8String]);
    json_t *item_data = json_object_get(data, key);
    json_t *item_children = json_object_get(item_data, "children");
    return that->lookup_id(json_string_value((json_array_get(item_children, index))));
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item {
    json_t *data = [self data];
    const char *key = (item == nil ? "#root" : [item UTF8String]);
    json_t *item_data = json_object_get(data, key);
    json_t *value_json = json_object_get(item_data, "expandable");
    return value_json ? json_bool_value(value_json) : YES;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isGroupItem:(id)item {
    json_t *data = [self data];
    const char *key = (item == nil ? "#root" : [item UTF8String]);
    json_t *item_data = json_object_get(data, key);
    json_t *value_json = json_object_get(item_data, "is-group");
    return value_json ? json_bool_value(value_json) : NO;
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item {
    json_t *data = [self data];
    const char *key = (item == nil ? "#root" : [item UTF8String]);
    json_t *item_data = json_object_get(data, key);
    json_t *value_json = json_object_get(item_data, "label");
    return json_nsstring_value(value_json);
}

- (void)outlineView:(NSOutlineView *)outlineView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn byItem:(id)item {

}

- (void)outlineView:(NSOutlineView *)outlineView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item {
    if ([cell respondsToSelector:@selector(setImage:)]) {
        json_t *data = [self data];
        const char *key = (item == nil ? "#root" : [item UTF8String]);
        json_t *item_data = json_object_get(data, key);
        const char *image_name = json_string_value(json_object_get(item_data, "image"));
        NSImage *image = nil;
        if (image_name) {
            image = nodeapp_ui_image_lookup(image_name);
            if (!image)
                image = [NSImage imageNamed:NSStr(image_name)];
            assert2(image, "Cannot find image '%s' of %s", image_name, that->path_);
        }
        [cell setImage:image];
    }
}

- (void)outlineView:(NSOutlineView *)outlineView mouseDownInHeaderOfTableColumn:(NSTableColumn *)tableColumn {

}

- (void)outlineView:(NSOutlineView *)outlineView didClickTableColumn:(NSTableColumn *)tableColumn {

}

- (void)outlineView:(NSOutlineView *)outlineView didDragTableColumn:(NSTableColumn *)tableColumn {

}

- (void)outlineViewSelectionDidChange:(NSNotification *)notification {
    NSOutlineView *outlineView = that->view_;
    NSInteger selectedRow = [outlineView selectedRow];
    if (selectedRow >= 0) {
        NSString *itemId = [outlineView itemAtRow:selectedRow];
        that->notify(json_object_2("selected", json_string([itemId UTF8String]), [itemId UTF8String], json_object_1("selected", json_true())));
    } else {
        that->notify(json_object_1("selected", json_null()));
    }
}

- (void)outlineViewItemWillExpand:(NSNotification *)notification {

}

- (void)outlineViewItemDidExpand:(NSNotification *)notification {

}

- (void)outlineViewItemWillCollapse:(NSNotification *)notification {

}

- (void)outlineViewItemDidCollapse:(NSNotification *)notification {

}

@end
