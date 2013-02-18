
#include "nodeapp_broker.h"

void C_broker__unretain(json_t *arg) {
    nodeapp_broker_unretain(json_broker_obj_id_value(arg));
}
