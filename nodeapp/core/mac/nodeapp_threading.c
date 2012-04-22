
#include "nodeapp_private.h"

#include <dispatch/dispatch.h>

void nodeapp_invoke_on_main_thread(INVOKE_LATER_FUNC func, void *context) {
    dispatch_async(dispatch_get_main_queue(), ^{
        func(context);
    });
}
