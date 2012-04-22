
#include "nodeapp.h"

#import <Cocoa/Cocoa.h>

json_t *C_app__display_popup_message(json_t *arg) {
    const char *title = json_string_value(json_object_get(arg, "title"));
    const char *text = json_string_value(json_object_get(arg, "text"));
    json_t *buttons = json_object_get(arg, "buttons");

    json_t *button1 = json_array_get(buttons, 0);
    json_t *button2 = json_array_get(buttons, 1);
    json_t *button3 = json_array_get(buttons, 2);

    const char *b1title = json_string_value(json_array_get(button1, 1));
    const char *b2title = json_string_value(json_array_get(button2, 1));
    const char *b3title = json_string_value(json_array_get(button3, 1));

    NSInteger response = [[NSAlert alertWithMessageText:NSStr(title) defaultButton:NSStr(b1title) alternateButton:NSStr(b2title) otherButton:NSStr(b3title) informativeTextWithFormat:@"%s", text] runModal];
    if (response == NSAlertDefaultReturn)
        return json_incref(json_array_get(button1, 0));
    if (response == NSAlertAlternateReturn)
        return json_incref(json_array_get(button2, 0));
    if (response == NSAlertOtherReturn)
        return json_incref(json_array_get(button3, 0));
    return json_string("error");
}

void C_app__reveal_file(json_t *arg) {
    [[NSWorkspace sharedWorkspace] selectFile:json_nsstring_value(json_object_get(arg, "file")) inFileViewerRootedAtPath:nil];
}

void C_app__open_url(json_t *arg) {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:json_nsstring_value(arg)]];
}

void C_app__terminate(json_t *arg) {
    [NSApp terminate:nil];
}
