
#import <stdarg.h>

#import "ShitHappens.h"

void _ShitHappened(NSString *subject, NSString *format, ...) {
    va_list va;
    va_start(va, format);
    NSString *message = [[[NSString alloc] initWithFormat:format arguments:va] autorelease];
    va_end(va);

    NSLog(@"SHIT HAPPENED: %@", message);
    [NSApp activateIgnoringOtherApps:YES];
    NSInteger reply = [[NSAlert alertWithMessageText:@"Shit happened in LiveReload" defaultButton:@"Contact Support" alternateButton:@"Ignore" otherButton:nil informativeTextWithFormat:@"Sorry, LiveReload has gone horribly wrong. Please contact support and attach the latest events from your Console.app.\n\nIncident details:\n\n%@\n%@", subject, message] runModal];
    if (reply == NSAlertDefaultReturn) {
        NSString *internalVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
        NSString *body = [NSString stringWithFormat:@"LiveReload version: %@\n\nI was doing this:\n1. ...\n2. ...\n\nwhen LiveReload suddenly blew up and told me this:\n\n%@\n%@", internalVersion, subject, message];
        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://help.livereload.com/discussion/new?discussion%%5Btitle%%5D=%@&discussion%%5Bbody%%5D=%@", [subject stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding], [body stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
        [[NSWorkspace sharedWorkspace] openURL:url];
    } else {
        NSLog(@"Ignoring shit.");
    }
}
