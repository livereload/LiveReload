
#include "nodeapp_ui_element.hh"
#include "nodeapp_rpc_proxy.h"


static void UIElement_free(void *arg) {
    delete (UIElement *)arg;
}


UIElement::UIElement(UIElement *parent_context, const char *id) {
    assert(id);
    assert(*id == '#');

    parent_context_ = parent_context;
    id_ = strdup(id);
    if (parent_context_)
        path_ = str_printf("%s %s", parent_context_->path_, id_);
    else
        path_ = strdup(id_);
    hashtable_init(&children_, jsonp_hash_str, jsonp_str_equal, NULL, UIElement_free);
}

UIElement::~UIElement() {
    hashtable_close(&children_);
    free(id_);
    free(path_);
}

UIElement *UIElement::resolve_child(const char *child_id, json_t *child_payload) {
    bool deletion = json_is_false(child_payload);

    UIElement *child_context = (UIElement *) hashtable_get(&children_, child_id);
    if (!child_context && !deletion) {
        child_context = create_child(child_id, child_payload);
        if (child_context) {
            hashtable_set(&children_, child_context->id_, child_context);
        }
    }

    if (deletion && child_context) {
        hashtable_del(&children_, child_id);
        return NULL;
    }

    return child_context;
}

void UIElement::update(json_t *payload) {
    pre_set(payload);
    for_each_object_key_value(payload, key, value) {
        if (*key == '#') {
            UIElement *child_context = resolve_child(key, value);
            if (!child_context)
                continue;
            child_context->update(value);
        } else if (*key == '$') {
            if (0 == strcmp(key, "$do")) {
                if (json_is_array(value)) {
                    for_each_array_item(value, funcs_index, funcs_spec) {
                        invoke_custom_funcs_and_handle_errors(funcs_spec);
                    }
                } else if (json_is_object(value)) {
                    invoke_custom_funcs_and_handle_errors(value);
                } else {
                    assert1(false, "Invalid data type in $do for element '%s'", path_);
                }
            } else {
                assert2(false, "Unknown meta '%s' for element '%s'", key, path_);
            }
        } else {
            bool ok = set(key, value);
            assert2(ok, "Unknown property '%s' set for element '%s'", key, path_);
        }
    }
    post_set(payload);
}

void UIElement::invoke_custom_funcs_and_handle_errors(json_t *spec) {
    for_each_object_key_value(spec, method, arg) {
        invoke_custom_func_and_handle_errors(method, arg);
    }
}

void UIElement::invoke_custom_func_and_handle_errors(const char *method, json_t *arg) {
    if (!invoke_custom_func(method, arg)) {
        if (parent_context_) {
            parent_context_->invoke_custom_func_and_handle_errors(method, arg);
        } else {
            assert1(false, "Custom func '%s' not found", method);
        }
    }
}

void UIElement::notify(json_t *payload) {
    json_t *parent_payload = json_object();
    json_object_set(parent_payload, id_, payload);
    parent_context_->notify(parent_payload);
}

UIElement *UIElement::create_child(const char *name, json_t *payload) {
    return NULL;
}

bool UIElement::set(const char *property, json_t *value) {
    if (0 == strcmp(property, "tags")) {
        // this property is used by the backend only, but we don't strip it for inspection and debugging purposes
        return true;
    }
    return false;
}

void UIElement::pre_set(json_t *payload) {
}

void UIElement::post_set(json_t *payload) {
}

bool UIElement::invoke_custom_func(const char *method, json_t *arg) {
    return false;
}



RootUIElement::RootUIElement(const char *_id) : UIElement(NULL, _id) {
}

void RootUIElement::notify(json_t *payload) {
    S_ui_notify(payload);
}



static UIElement *root_context;

void nodeapp_ui_context_init() {
    if (root_context)
        return;
    root_context = UIElement::create_root_context();
}


extern "C"
void C_ui__update(json_t *payload) {
    nodeapp_ui_context_init();
    root_context->update(payload);
}

extern "C"
void nodeapp_ui_reset() {
    if (root_context) {
        delete root_context;
        root_context = NULL;
    }
}
