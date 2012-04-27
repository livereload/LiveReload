#ifndef nodeapp_ui_osdep_h
#define nodeapp_ui_osdep_h

#include "nodeapp_ui_element.hh"


class ApplicationUIElement : public RootUIElement {
public:
    ApplicationUIElement();

protected:
    virtual UIElement *create_child(const char *name, json_t *payload);
};


class WindowUIElement : public UIElement {
public:
    WindowUIElement(UIElement *parent_context, const char *id, Class klass);
    virtual ~WindowUIElement();

protected:
    NSWindowController *windowController_;

    virtual UIElement *create_child(const char *name, json_t *payload);
    virtual bool set(const char *property, json_t *value);
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

    virtual const char *action_event_name();
};

class GenericViewUIElement : public ViewUIElement {
public:
    GenericViewUIElement(UIElement *parent_context, const char *_id, id view);
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


class ButtonUIElement : public ViewUIElement {
public:
    ButtonUIElement(UIElement *parent_context, const char *_id, id view);
    //protected:
};


class TextFieldUIElement : public ViewUIElement {
public:
    TextFieldUIElement(UIElement *parent_context, const char *_id, id view);
protected:
    virtual bool set(const char *property, json_t *value);
};



@interface UIElementDelegate : NSObject {
@public
    ViewUIElement *_element;
}

- (IBAction)perform:(id)sender;

@end

@interface OutlineUIElementDelegate : UIElementDelegate <NSOutlineViewDataSource, NSOutlineViewDelegate>
@end


#endif
