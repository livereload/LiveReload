#include "nodeapp_ui_element_osdep_window.hh"
#include "nodeapp_ui_element_osdep_utils.hh"

#include "nodeapp_ui_element_osdep_generic.hh"
#include "nodeapp_ui_element_osdep_button.hh"
#include "nodeapp_ui_element_osdep_textfield.hh"
#include "nodeapp_ui_element_osdep_outline.hh"
#include "nodeapp_ui_element_osdep_table.hh"
// #include "nodeapp_ui_element_osdep_.hh"


WindowUIElement::WindowUIElement(UIElement *parent_context, const char *id, NSWindowController *windowController) : UIElement(parent_context, id), ObjCObject([WindowUIElementDelegate class])
{
    window_type_ = WindowTypeNormal;
    parent_window_element_ = NULL;

    windowController_ = [windowController retain];
    [[windowController_ window] setDelegate:self()]; // load window
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
    else if ([view isKindOfClass:[NSTableView class]])
        return new TableUIElement(this, name, view);
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
                    [NSApp beginSheet:[windowController_ window] modalForWindow:parentWindow modalDelegate:self() didEndSelector:@selector(didEndProjectSettingsSheet:returnCode:contextInfo:) contextInfo:NULL];
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


@implementation WindowUIElementDelegate

#define that ObjCObject::from_id<WindowUIElement>(self)

- (void)windowDidBecomeKey:(NSNotification *)notification {
    printf("windowDidBecomeKey, el = %p\n", that);
}

- (void)didEndProjectSettingsSheet:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
    [sheet orderOut:self];
}

@end
