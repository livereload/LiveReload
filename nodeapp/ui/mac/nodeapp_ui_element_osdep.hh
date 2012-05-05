#ifndef nodeapp_ui_osdep_h
#define nodeapp_ui_osdep_h

#include "nodeapp_ui_element.hh"


#ifdef __APPLE__
bool invoke_custom_func_in_nsobject(id object, const char *method, json_t *arg);
#endif


@class WindowUIElementDelegate;


// Fakes an Objective-C class out of a C++ class.
//
// Note that this is a very bad and completely superfluous idea, but after looking up a way
// to build Objective-C classes at run time, I just had to do this no matter what. (Besides,
// I really hated maintaining mutual pointers in UIElement/UIElementDelegate class pairs.)
//
// Building up a whole class from scratch (objc_allocateClassPair) looked like a lot of trouble,
// so I compile a real Objective-C class instead, but instead of instantiating it by regular means
// (alloc/init or class_createInstance), I simply cast a part of a C++ object to (id).
// I've looked at the source code for class_createInstance and this hack should work perfectly,
// but of course we're relying on a private implementation detail of Objective-C runtime here.
//
// The beauty is that if I inherit from ObjCObject, I can let C++ figure out the pointer arithmetic
// necessary to convert between (SomeUIElement *) and (ObjCObject *, aka id).
//
// Our use case is so trivial that it makes no sense to apply any kind of tricks here. However,
// again, I couldn't help myself, and hey, it's my product, I want to have fun writing it.
class ObjCObject {
public:
    Class isa;
    // NSObject holds reference counts in a separate hashtable, so we don't need to allocate space for that

    ObjCObject(Class isa) {
        this->isa = isa;
    }

    id self() {
        return (id)this;
    }

    template <typename T>
    static T *from_id(id obj) {
        return static_cast<T *>(reinterpret_cast<ObjCObject *>(obj));
    }
private:
    // CoreFoundation wants ObjC classes to be at least 16 bytes in length,
    void *_cf_filler[3];
};


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


class WindowUIElement : public UIElement, public ObjCObject {
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


class ViewUIElement : public UIElement, public ObjCObject {
public:
    ViewUIElement(UIElement *parent_context, const char *_id, id view, Class delegate_klass);
    virtual ~ViewUIElement();
    
    virtual void on_action();

    id view_;
protected:
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



@interface WindowUIElementDelegate : NSObject <NSWindowDelegate>
@end

@interface UIElementDelegate : NSObject

- (IBAction)perform:(id)sender;

@end

@interface OutlineUIElementDelegate : UIElementDelegate <NSOutlineViewDataSource, NSOutlineViewDelegate>
@end

@interface TextFieldUIElementDelegate : UIElementDelegate <NSTextFieldDelegate>
@end


#endif
