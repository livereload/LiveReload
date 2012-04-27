#ifndef nodeapp_ui_h
#define nodeapp_ui_h

#include "nodeapp.h"

extern "C" {
#include "hashtable.h"
}


class UIElement {
public:
    UIElement(UIElement *parent_context, const char *id);
    virtual ~UIElement();

    void update(json_t *payload);
    virtual void notify(json_t *payload);
    
    static UIElement *create_root_context();

protected:
    UIElement *parent_context_;
    char *id_;
    char *path_;
    hashtable_t children_;

    UIElement *resolve_child(const char *name, json_t *payload);

protected:
    // override points for children
    virtual UIElement *create_child(const char *name, json_t *payload);
    virtual bool set(const char *property, json_t *value);
};


class RootUIElement : public UIElement {
public:
    RootUIElement(const char *id);

    virtual void notify(json_t *payload);
};

#endif
