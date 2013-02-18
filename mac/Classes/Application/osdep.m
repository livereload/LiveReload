
#include "common.h"
#include "jansson.h"

#import <Cocoa/Cocoa.h>

void C_app__failed_to_start(json_t *arg) {
    const char *msg = json_string_value(json_object_get(arg, "message"));
    [[NSAlert alertWithMessageText:@"LiveReload failed to start" defaultButton:@"Quit" alternateButton:nil otherButton:nil informativeTextWithFormat:@"%s", msg] runModal];
    [NSApp terminate:nil];
}
