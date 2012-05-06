#ifndef nodeapp_ui_element_osdep_window_hh
#define nodeapp_ui_element_osdep_window_hh

#include "nodeapp_ui_element.hh"
#include "nodeapp_ui_objcobject.hh"


typedef enum {
    WindowTypeNormal,
    WindowTypeSheet,
} WindowType;


class WindowUIElement : public UIElement, public ObjCObject {
public:
    WindowUIElement(UIElement *parent_context, const char *id, NSWindowController *windowController);
    virtual ~WindowUIElement();

protected:
    NSWindowController *windowController_;
    WindowUIElement *parent_window_element_;
    WindowType window_type_;

    virtual UIElement *create_child(const char *name, json_t *payload);
    virtual void pre_set(json_t *payload);
    virtual bool set(const char *property, json_t *value);
    virtual bool invoke_custom_func(const char *method, json_t *arg);
};

@interface WindowUIElementDelegate : NSObject <NSWindowDelegate>
@end

#endif
