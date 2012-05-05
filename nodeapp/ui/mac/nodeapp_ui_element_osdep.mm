
#include "nodeapp_ui.h"
#include "nodeapp_ui_element.hh"
#include "nodeapp_ui_element_osdep.hh"

#import <Cocoa/Cocoa.h>
#include <objc/runtime.h>


#define hex2i(string, start, len, result) [[NSScanner scannerWithString:[string substringWithRange:NSMakeRange(start, len)]] scanHexInt:result]

NSColor *NSColorFromStringSpec(NSString *spec) {
    NSCAssert1([spec characterAtIndex:0] == '#', @"Invalid color format: '%@'", spec);
    unsigned red, green, blue, alpha = 255;
    BOOL ok;
    switch ([spec length]) {
        case 4:
            ok = hex2i(spec, 1, 1, &red) && hex2i(spec, 2, 1, &green) && hex2i(spec, 3, 1, &blue);
            red   = (red   << 4) + red;
            green = (green << 4) + green;
            blue  = (blue  << 4) + blue;
            break;
        case 7:
            ok = hex2i(spec, 1, 2, &red) && hex2i(spec, 3, 2, &green) && hex2i(spec, 5, 2, &blue);
            break;
        case 9:
            ok = hex2i(spec, 1, 2, &red) && hex2i(spec, 3, 2, &green) && hex2i(spec, 5, 2, &blue) && hex2i(spec, 7, 2, &alpha);
            break;
        default:
            ok = NO;
            break;
    }
    NSCAssert1(ok, @"Invalid color format: '%@'", spec);
    return [NSColor colorWithCalibratedRed:red/255.0 green:green/255.0 blue:blue/255.0 alpha:alpha/255.0];
}

bool invoke_custom_func_in_nsobject(id object, const char *method, json_t *arg) {
    NSString *selectorName = [NSString stringWithFormat:@"%s:", method];
    SEL selector = NSSelectorFromString(selectorName);
    if ([object respondsToSelector:selector]) {
        if (*[[object methodSignatureForSelector:selector] getArgumentTypeAtIndex:2] == '@') {
            // accepts NSDictionary *
            [object performSelector:selector withObject:nodeapp_json_to_objc(arg, YES)];
        } else {
            // accepts json_t *; signature returned by getArgumentTypeAtIndex looks like ^{...bullshit...}
            IMP imp = [object methodForSelector:selector];
            imp(object, selector, arg);
        }
        return true;
    } else {
        return false;
    }
}

int parse_enum(const char *name, ...) {
    va_list va;
    const char *candidate;
    int index = 0;

    va_start(va, name);
    while (!!(candidate = va_arg(va, const char *))) {
        if (0 == strcmp(name, candidate))
            return index;
        ++index;
    }
    va_end(va);

    assert1(NO, "Not a valid enumeration identifier: '%s'", name);
}


ApplicationUIElement::ApplicationUIElement() : RootUIElement("#application") {
}

UIElement *ApplicationUIElement::create_child(const char *name, json_t *payload) {
    NSString *className = json_nsstring_value(json_object_get(payload, "type"));
    assert(className && "New window payload must specify a 'type'");

    NSString *controllerClassName = [NSString stringWithFormat:@"%@Controller", className];
    Class klass = NSClassFromString(controllerClassName);
    assert(klass && "Window controller class not found for the specified window type");

    NSWindowController *windowController = [[[klass alloc] initWithWindowNibName:className] autorelease];
    return new WindowUIElement(this, name, windowController);
}

bool ApplicationUIElement::invoke_custom_func(const char *method, json_t *arg) {
    return invoke_custom_func_in_nsobject([NSApp delegate], method, arg);
}



WindowUIElement::WindowUIElement(UIElement *parent_context, const char *id, NSWindowController *windowController) : UIElement(parent_context, id)
{
    window_type_ = WindowTypeNormal;
    parent_window_element_ = NULL;

    delegate_ = [[WindowUIElementDelegate alloc] init];
    delegate_->_element = this;

    windowController_ = [windowController retain];
    [windowController_ window]; // load
}

WindowUIElement::~WindowUIElement() {
    if ([windowController_ isWindowLoaded]) {
        [windowController_ close];
    }
    [windowController_ release];
    [delegate_ release];
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
    else if ([view isKindOfClass:[NSControl class]])
        return new GenericControlUIElement(this, name, view);
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
                if (WindowTypeSheet == window_type_ && !!parent_window_element_) {
                    NSWindow *parentWindow = [parent_window_element_->windowController_ window];
                    [NSApp beginSheet:[windowController_ window] modalForWindow:parentWindow modalDelegate:delegate_ didEndSelector:@selector(didEndProjectSettingsSheet:returnCode:contextInfo:) contextInfo:NULL];
                } else {
                    [windowController_ showWindow:nil];
                }
            } else {
                if (WindowTypeSheet == window_type_ && !!parent_window_element_) {
                    [NSApp endSheet:[windowController_ window]];
                } else {
                    [windowController_ close];
                }
            }
        }
        return true;
    } else {
        return UIElement::set(property, value);
    }
}

void WindowUIElement::pre_set(json_t *payload) {
    if (const char *parent_window_id = json_object_extract_string(payload, "parent-window")) {
        WindowUIElement *parent_window_element = dynamic_cast<WindowUIElement *>(parent_context_->resolve_child(parent_window_id, NULL));
        parent_window_element_ = parent_window_element;
        // TODO: notify the window that it now has a parent
    }
    if (const char *window_type_str = json_object_extract_string(payload, "parent-style")) {
        window_type_ = (WindowType) parse_enum(window_type_str, "normal", "sheet", NULL);
    }
    UIElement::pre_set(payload);
}

bool WindowUIElement::invoke_custom_func(const char *method, json_t *arg) {
    return invoke_custom_func_in_nsobject(windowController_, method, arg);
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

bool ViewUIElement::invoke_custom_func(const char *method, json_t *arg) {
    return invoke_custom_func_in_nsobject(view_, method, arg);
}

void ViewUIElement::on_action() {
}

void ViewUIElement::hook_action() {
    [view_ setTarget:delegate_];
    [view_ setAction:@selector(perform:)];
}


GenericViewUIElement::GenericViewUIElement(UIElement *parent_context, const char *_id, id view) : ViewUIElement(parent_context, _id, view, [UIElementDelegate class]) {
}


GenericControlUIElement::GenericControlUIElement(UIElement *parent_context, const char *_id, id view) : ControlUIElement(parent_context, _id, view, [UIElementDelegate class]) {
}


ControlUIElement::ControlUIElement(UIElement *parent_context, const char *_id, id view, Class delegate_klass) : ViewUIElement(parent_context, _id, view, delegate_klass) {
    hook_action();
}

bool ControlUIElement::set(const char *property, json_t *value) {
    if (0 == strcmp(property, "cell-background-style")) {
        const char *style = json_string_value(value);
        if (!style) {
            assert1(json_is_string(value), "Unsupported value for cell-background-style of %s", path_);
        } if (0 == strcmp(style, "raised")) {
            [[view_ cell] setBackgroundStyle:NSBackgroundStyleRaised];
        } else if (0 == strcmp(style, "lowered")) {
            [[view_ cell] setBackgroundStyle:NSBackgroundStyleLowered];
        } else if (0 == strcmp(style, "light")) {  // the default
            [[view_ cell] setBackgroundStyle:NSBackgroundStyleDark];
        } else if (0 == strcmp(style, "dark")) {
            [[view_ cell] setBackgroundStyle:NSBackgroundStyleLight];
        } else {
            assert2(json_is_string(value), "Unsupported value '%s' for cell-background-style of %s", style, path_);
        }
        return true;
    } else {
        return UIElement::set(property, value);
    }
}


ButtonUIElement::ButtonUIElement(UIElement *parent_context, const char *_id, id view) : ControlUIElement(parent_context, _id, view, [UIElementDelegate class]) {
    hook_action();
}


void ButtonUIElement::on_action() {
    json_t *state;
    if ([view_ state] == NSOnState)
        state = json_true();
    else if ([view_ state] == NSOffState)
        state = json_false();
    else
        state = json_string("mixed");
    notify(json_object_1("clicked", state));
}

bool ButtonUIElement::set(const char *property, json_t *value) {
    if (0 == strcmp(property, "state")) {
        if (json_is_true(value))
            [view_ setState:NSOnState];
        else if (json_is_false(value))
            [view_ setState:NSOffState];
        else if (json_is_string(value) && 0 == strcmp("mixed", json_string_value(value)))
            [view_ setState:NSMixedState];
        else
            assert1(json_is_string(value), "Unsupported value for 'state' property of %s", path_);
        return true;
    } else {
        return ControlUIElement::set(property, value);
    }
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



void StyleHyperlink(NSTextField *label, NSString *string, NSURL *url, NSColor *linkColor) {
    // both are needed, otherwise hyperlink won't accept mousedown
    [label setAllowsEditingTextAttributes:YES];
    [label setSelectable:YES];

    // attributes
    NSShadow *shadow = [[[NSShadow alloc] init] autorelease];
    NSMutableParagraphStyle *paragraphStyle = [[[NSMutableParagraphStyle alloc] init] autorelease];
    [paragraphStyle setAlignment:label.alignment];
    if (!linkColor)
        linkColor = label.textColor;
    NSDictionary *linkAttributes = [NSDictionary dictionaryWithObjectsAndKeys:linkColor, NSForegroundColorAttributeName, [NSNumber numberWithInt:NSSingleUnderlineStyle], NSUnderlineStyleAttributeName, url, NSLinkAttributeName, label.font, NSFontAttributeName, shadow, NSShadowAttributeName, paragraphStyle, NSParagraphStyleAttributeName, nil];
    
    NSRange range = [string rangeOfString:@"_["];
    if (range.location == NSNotFound) {
        label.attributedStringValue = [[[NSAttributedString alloc] initWithString:string attributes:linkAttributes] autorelease];
    } else {
        NSString *prefix = [string substringToIndex:range.location];
        string = [string substringFromIndex:range.location + range.length];
        
        range = [string rangeOfString:@"]_"];
        NSCAssert(range.length > 0, @"Partial hyperlink must contain ]_ marker");
        NSString *link = [string substringToIndex:range.location];
        NSString *suffix = [string substringFromIndex:range.location + range.length];
        
        NSMutableAttributedString *as = [[[NSMutableAttributedString alloc] init] autorelease];
        
        
        [as appendAttributedString:[[[NSAttributedString alloc] initWithString:prefix attributes:[NSDictionary dictionaryWithObjectsAndKeys:label.textColor, NSForegroundColorAttributeName, shadow, NSShadowAttributeName, paragraphStyle, NSParagraphStyleAttributeName, label.font, NSFontAttributeName, nil]] autorelease]];
        
        [as appendAttributedString:[[[NSAttributedString alloc] initWithString:link attributes:linkAttributes] autorelease]];
        
        [as appendAttributedString:[[[NSAttributedString alloc] initWithString:suffix attributes:[NSDictionary dictionaryWithObjectsAndKeys:label.textColor, NSForegroundColorAttributeName, shadow, NSShadowAttributeName, paragraphStyle, NSParagraphStyleAttributeName, label.font, NSFontAttributeName, nil]] autorelease]];

        label.attributedStringValue = as;
    }
}

TextFieldUIElement::TextFieldUIElement(UIElement *parent_context, const char *_id, id view) : ControlUIElement(parent_context, _id, view, [UIElementDelegate class]) {
}

bool TextFieldUIElement::set(const char *property, json_t *value) {
    return ControlUIElement::set(property, value);
}

void TextFieldUIElement::pre_set(json_t *payload) {
    NSString *text = json_object_extract_nsstring(payload, "text");
    NSString *hyperlink_url = json_object_extract_nsstring(payload, "hyperlink-url");
    NSString *hyperlink_color = json_object_extract_nsstring(payload, "hyperlink-color");
    if (text || hyperlink_url) {
        if (!text)
            text = [view_ stringValue];
        if (hyperlink_url) {
            StyleHyperlink(view_, text, [NSURL URLWithString:hyperlink_url], (hyperlink_color ? NSColorFromStringSpec(hyperlink_color) : nil));
        } else {
            [view_ setStringValue:text];
        }
    }
    ControlUIElement::pre_set(payload);
}




UIElement *UIElement::create_root_context() {
    return new ApplicationUIElement();
}


@implementation WindowUIElementDelegate

- (void)didEndProjectSettingsSheet:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
    [sheet orderOut:self];
}

@end


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
