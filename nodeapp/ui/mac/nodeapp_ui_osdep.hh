#ifndef nodeapp_ui_osdep_h
#define nodeapp_ui_osdep_h

#include "nodeapp_ui.hh"


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
    ViewUIElement(UIElement *parent_context, const char *_id, id view);
    virtual ~ViewUIElement();
    
    virtual void on_action();
protected:
    id view_;
    id delegate_;
    
    void hook_action();

    virtual id new_delegate();
    virtual const char *action_event_name();
};



@interface UIElementDelegate : NSObject {
@public
    ViewUIElement *_element;
}

- (IBAction)perform:(id)sender;

@end


class ButtonUIElement : public ViewUIElement {
public:
    ButtonUIElement(UIElement *parent_context, const char *_id, id view);
//protected:
};


#endif
