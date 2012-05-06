#ifndef nodeapp_ui_element_osdep_utils_hh
#define nodeapp_ui_element_osdep_utils_hh

#include "nodeapp_ui_element.hh"


#define hex2i(string, start, len, result) [[NSScanner scannerWithString:[string substringWithRange:NSMakeRange(start, len)]] scanHexInt:result]


bool invoke_custom_func_in_nsobject(id object, const char *method, json_t *arg);

NSColor *NSColorFromStringSpec(NSString *spec);

int parse_enum(const char *name, ...);


#endif
