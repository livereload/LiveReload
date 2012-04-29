
#include "nodeapp.h"

void NodeAppRpcInvokeAndKeepCallback(NSString *callback, id arg) {
    nodeapp_rpc_invoke_and_keep_callback([callback UTF8String], nodeapp_objc_to_json(arg));
}

void NodeAppRpcInvokeAndDisposeCallback(NSString *callback, id arg) {
    nodeapp_rpc_invoke_and_dispose_callback([callback UTF8String], nodeapp_objc_to_json(arg));
}

void NodeAppRpcDisposeCallback(NSString *callback) {
    nodeapp_rpc_dispose_callback([callback UTF8String]);
}
