#ifndef nodeapp_broker_h
#define nodeapp_broker_h


// provides RPC for native objects


#include "nodeapp.h"


typedef int nodeapp_broker_obj_id_t;

#define json_broker_obj_id       json_integer
#define json_broker_obj_id_value json_integer_value


#include "nodeapp_broker_osdep.h"


#endif
