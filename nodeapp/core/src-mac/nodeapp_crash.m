
#include "nodeapp_private.h"

void nodeapp_emergency_shutdown_backend_crashed(const char *reason) {
    char *message = str_printf(NODEAPP_BACKENDCRASH_TEXT, reason);
    NSInteger result = [[NSAlert alertWithMessageText:@"" NODEAPP_BACKENDCRASH_TITLE defaultButton:@"" NODEAPP_BACKENDCRASH_BUTTON_HELP alternateButton:@"" NODEAPP_BACKENDCRASH_BUTTON_QUIT otherButton:nil informativeTextWithFormat:@"%s", message] runModal];
    if (result == NSAlertDefaultReturn) {
        NSString *logFile = NSStr(nodeapp_log_file);
        [[NSWorkspace sharedWorkspace] selectFile:logFile inFileViewerRootedAtPath:nil];
        [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"" NODEAPP_BACKENDCRASH_BUTTON_HELP_URL]];
    }
    [NSApp terminate:nil];
}
