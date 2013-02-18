#ifndef nodeapp_broker_osdep_h
#define nodeapp_broker_osdep_h

// mapping
#ifdef __OBJC__
id nodeapp_broker_resolve(nodeapp_broker_obj_id_t obj_id);
nodeapp_broker_obj_id_t nodeapp_broker_obj_id(id object);
nodeapp_broker_obj_id_t nodeapp_broker_expose(id object);
#endif

// retaining
nodeapp_broker_obj_id_t nodeapp_broker_retain(nodeapp_broker_obj_id_t obj_id);
void nodeapp_broker_unretain(nodeapp_broker_obj_id_t obj_id);

// json helpers
#ifdef __OBJC__
id json_broker_object_value(json_t *obj_id_json);
json_t *json_broker_object(id object);
json_t *json_broker_object_retained(id object);
json_t *nodeapp_objc_to_json_with_broker(id value);
#endif

#endif
