
#include "nodeapp_private.h"

void nodeapp_emergency_shutdown_backend_crashed() {
    NSInteger result = [[NSAlert alertWithMessageText:@"" NODEAPP_BACKENDCRASH_TITLE defaultButton:@"" NODEAPP_BACKENDCRASH_BUTTON_HELP alternateButton:@"" NODEAPP_BACKENDCRASH_BUTTON_QUIT otherButton:nil informativeTextWithFormat:@"" NODEAPP_BACKENDCRASH_TEXT] runModal];
    if (result == NSAlertDefaultReturn) {
        NSString *logFile = NSStr(nodeapp_log_file);
        [[NSWorkspace sharedWorkspace] selectFile:logFile inFileViewerRootedAtPath:nil];
        [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"" NODEAPP_BACKENDCRASH_BUTTON_HELP_URL]];
    }
    [NSApp terminate:nil];
}
