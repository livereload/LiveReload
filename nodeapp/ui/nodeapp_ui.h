#ifndef nodeapp_ui_h
#define nodeapp_ui_h

#include "nodeapp.h"


#ifdef __cplusplus
extern "C" {
#endif


#ifdef __APPLE__
#import <Cocoa/Cocoa.h>

void nodeapp_ui_image_register(const char *name, NSImage *image);
NSImage *nodeapp_ui_image_lookup(const char *name);
void nodeapp_ui_reset();
#endif
    

#ifdef __cplusplus
}
#endif

#endif
