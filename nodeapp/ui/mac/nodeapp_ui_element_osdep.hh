#ifndef nodeapp_ui_osdep_h
#define nodeapp_ui_osdep_h

#include "nodeapp_ui_element.hh"


#ifdef __APPLE__
bool invoke_custom_func_in_nsobject(id object, const char *method, json_t *arg);
#endif


@class WindowUIElementDelegate;


class ApplicationUIElement : public RootUIElement {
public:
    ApplicationUIElement();

protected:
    virtual UIElement *create_child(const char *name, json_t *payload);
    virtual bool invoke_custom_func(const char *method, json_t *arg);
};


typedef enum {
    WindowTypeNormal,
    WindowTypeSheet,
} WindowType;


class WindowUIElement : public UIElement {
public:
    WindowUIElement(UIElement *parent_context, const char *id, NSWindowController *windowController);
    virtual ~WindowUIElement();

protected:
    NSWindowController *windowController_;
    WindowUIElementDelegate *delegate_;
    WindowUIElement *parent_window_element_;
    WindowType window_type_;

    virtual UIElement *create_child(const char *name, json_t *payload);
    virtual void pre_set(json_t *payload);
    virtual bool set(const char *property, json_t *value);
    virtual bool invoke_custom_func(const char *method, json_t *arg);
};


class ViewUIElement : public UIElement {
public:
    ViewUIElement(UIElement *parent_context, const char *_id, id view, Class delegate_klass);
    virtual ~ViewUIElement();
    
    virtual void on_action();

    id view_;
protected:
    id delegate_;
    
    void hook_action();

    virtual bool set(const char *property, json_t *value);

    virtual bool invoke_custom_func(const char *method, json_t *arg);
};


class ControlUIElement : public ViewUIElement {
public:
    ControlUIElement(UIElement *parent_context, const char *_id, id view, Class delegate_klass);
protected:
    virtual bool set(const char *property, json_t *value);
};


class GenericViewUIElement : public ViewUIElement {
public:
    GenericViewUIElement(UIElement *parent_context, const char *_id, id view);
};


class GenericControlUIElement : public ControlUIElement {
public:
    GenericControlUIElement(UIElement *parent_context, const char *_id, id view);
};


class OutlineUIElement : public ViewUIElement {
public:
    OutlineUIElement(UIElement *parent_context, const char *_id, id view);
    virtual ~OutlineUIElement();

    json_t *data_;
    NSString *lookup_id(const char *item_id);
protected:
    NSMutableDictionary *item_ids_;

    virtual bool set(const char *property, json_t *value);
};


class ButtonUIElement : public ControlUIElement {
public:
    ButtonUIElement(UIElement *parent_context, const char *_id, id view);

    virtual void on_action();
protected:
    virtual bool set(const char *property, json_t *value);
};


class TextFieldUIElement : public ControlUIElement {
public:
    TextFieldUIElement(UIElement *parent_context, const char *_id, id view);
protected:
    virtual bool set(const char *property, json_t *value);
    virtual void pre_set(json_t *payload);
};



@interface WindowUIElementDelegate : NSObject <NSWindowDelegate> {
@public
    WindowUIElement *_element;
}
@end

@interface UIElementDelegate : NSObject {
@public
    ViewUIElement *_element;
}

- (IBAction)perform:(id)sender;

@end

@interface OutlineUIElementDelegate : UIElementDelegate <NSOutlineViewDataSource, NSOutlineViewDelegate>
@end


#endif
