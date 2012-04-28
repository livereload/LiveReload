
#include "nodeapp_ui.h"
#include "nodeapp_ui_element.hh"
#include "nodeapp_ui_element_osdep.hh"

#import <Cocoa/Cocoa.h>
#include <objc/runtime.h>


ApplicationUIElement::ApplicationUIElement() : RootUIElement("#application") {
}

UIElement *ApplicationUIElement::create_child(const char *name, json_t *payload) {
    NSString *className = json_nsstring_value(json_object_get(payload, "type"));
    assert(className && "New window payload must specify a 'type'");

    NSString *controllerClassName = [NSString stringWithFormat:@"%@Controller", className];
    Class klass = NSClassFromString(controllerClassName);
    assert(klass && "Window controller class not found for the specified window type");

    return new WindowUIElement(this, name, klass);
}


WindowUIElement::WindowUIElement(UIElement *parent_context, const char *id, Class klass) : UIElement(parent_context, id) {
    windowController_ = [[klass alloc] init];
    [windowController_ window]; // load
}

WindowUIElement::~WindowUIElement() {
    if ([windowController_ isWindowLoaded]) {
        [windowController_ close];
    }
    [windowController_ release];
}

UIElement *WindowUIElement::create_child(const char *name, json_t *payload) {
    const char *outlet_name = name + 1;
    id view = [windowController_ valueForKey:NSStr(outlet_name)];
    assert2(view, "Cannot find outlet '%s' in window '%s'", outlet_name, path_);
    
    if ([view isKindOfClass:[NSButton class]])
        return new ButtonUIElement(this, name, view);
    else if ([view isKindOfClass:[NSOutlineView class]])
        return new OutlineUIElement(this, name, view);
    else if ([view isKindOfClass:[NSTextField class]])
        return new TextFieldUIElement(this, name, view);
    else
        return new GenericViewUIElement(this, name, view);
}

bool WindowUIElement::set(const char *property, json_t *value) {
    if (0 == strcmp(property, "type")) {
        // handled earlier; ignore
        return true;
    } else if (0 == strcmp(property, "visible")) {
        bool v = json_bool_value(value);
        NSWindow *window = [windowController_ window];
        if ([window isVisible] != v) {
            if (v) {
                [windowController_ showWindow:nil];
            } else {
                [windowController_ close];
            }
        }
        return true;
    } else {
        return UIElement::set(property, value);
    }
}



ViewUIElement::ViewUIElement(UIElement *parent_context, const char *_id, id view, Class delegate_klass) : UIElement(parent_context, _id) {
    view_ = [view retain];
    delegate_ = [[delegate_klass alloc] init];
    if (delegate_)
        ((UIElementDelegate *)delegate_)->_element = this;
}

ViewUIElement::~ViewUIElement() {
    [view_ release];
    [delegate_ release];
}

bool ViewUIElement::set(const char *property, json_t *value) {
    if (0 == strcmp(property, "visible")) {
        bool hidden = !json_bool_value(value);
        if ([view_ isHidden] != hidden) {
            [view_ setHidden:hidden];
        }
        return true;
    } else if (0 == strcmp(property, "placeholder")) {
        const char *placeholder = json_string_value(value);
        UIElement *element = parent_context_->resolve_child(placeholder, NULL);
        assert2(element, "Cannot find placeholder element '%s' around %s", placeholder, path_);
        ViewUIElement *viewEl = dynamic_cast<ViewUIElement *>(element);
        assert2(viewEl, "Placeholder element '%s' (around %s) must be a view", placeholder, path_);
        NSView *placeholderView = viewEl->view_;
        
        if ([view_ superview] != [placeholderView superview]) {
            [view_ removeFromSuperview];
            [[placeholderView superview] addSubview:view_ positioned:NSWindowBelow relativeTo:placeholderView];
        }
        [view_ setFrame:[placeholderView frame]];
        [(NSView *)view_ setAutoresizingMask:[placeholderView autoresizingMask]];
        return true;
    } else {
        return UIElement::set(property, value);
    }
}

void ViewUIElement::hook_action() {
    [view_ setTarget:delegate_];
    [view_ setAction:@selector(perform:)];
}

void ViewUIElement::on_action() {
    notify(json_object_1(action_event_name(), json_true()));
}

const char *ViewUIElement::action_event_name() {
    return "clicked";
}


GenericViewUIElement::GenericViewUIElement(UIElement *parent_context, const char *_id, id view) : ViewUIElement(parent_context, _id, view, [UIElementDelegate class]) {
}

ButtonUIElement::ButtonUIElement(UIElement *parent_context, const char *_id, id view) : ViewUIElement(parent_context, _id, view, [UIElementDelegate class]) {
    hook_action();
}


OutlineUIElement::OutlineUIElement(UIElement *parent_context, const char *_id, id view) : ViewUIElement(parent_context, _id, view, [OutlineUIElementDelegate class]) {
    item_ids_ = [[NSMutableDictionary alloc] init];
    data_ = json_object_1("#root", json_object_1("children", json_array()));

    NSOutlineView *outlineView = view_;
    [outlineView setDataSource:delegate_];
    [outlineView setDelegate:delegate_];
}

OutlineUIElement::~OutlineUIElement() {
    json_decref(data_);
    [item_ids_ release];
}

NSString *OutlineUIElement::lookup_id(const char *item_id) {
    NSString *itemId = NSStr(item_id);
    NSString *result = [item_ids_ objectForKey:itemId];
    if (!result) {
        result = itemId;
        [item_ids_ setObject:result forKey:itemId];
    }
    return result;
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
    } else if (0 == strcmp(property, "dnd-drop-types")) {
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



TextFieldUIElement::TextFieldUIElement(UIElement *parent_context, const char *_id, id view) : ViewUIElement(parent_context, _id, view, [UIElementDelegate class]) {
}

bool TextFieldUIElement::set(const char *property, json_t *value) {
    if (0 == strcmp(property, "text")) {
        [view_ setStringValue:json_nsstring_value(value)];
        return true;
    } else {
        return ViewUIElement::set(property, value);
    }
}




UIElement *UIElement::create_root_context() {
    return new ApplicationUIElement();
}


@implementation UIElementDelegate

- (IBAction)perform:(id)sender {
    if (_element)
        _element->on_action();
}

@end


@implementation OutlineUIElementDelegate

- (json_t *)data {
    return ((OutlineUIElement *)_element)->data_;
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
    return ((OutlineUIElement *)_element)->lookup_id(json_string_value((json_array_get(item_children, index))));
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
            assert2(image, "Cannot find image '%s' of %s", image_name, _element->path_);
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
    NSOutlineView *outlineView = _element->view_;
    NSInteger selectedRow = [outlineView selectedRow];
    if (selectedRow >= 0) {
        NSString *itemId = [outlineView itemAtRow:selectedRow];
        _element->notify(json_object_2("selected", json_string([itemId UTF8String]), [itemId UTF8String], json_object_1("selected", json_true())));
    } else {
        _element->notify(json_object_1("selected", json_null()));
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
