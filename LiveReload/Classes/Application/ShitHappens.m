
#import <stdarg.h>

#import "ShitHappens.h"

void TenderDisplayHelp() {
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://go.livereload.com/help"]];
    [[NSWorkspace sharedWorkspace] openURL:url];
}

void TenderShowArticle(NSString *url) {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:url]];
}

void _ShitHappened(NSString *subject, NSString *format, ...) {
    va_list va;
    va_start(va, format);
    NSString *message = [[[NSString alloc] initWithFormat:format arguments:va] autorelease];
    va_end(va);

    NSLog(@"SHIT HAPPENED: %@", message);
    [NSApp activateIgnoringOtherApps:YES];
    NSInteger reply = [[NSAlert alertWithMessageText:@"Shit happened in LiveReload" defaultButton:@"Contact Support" alternateButton:@"Ignore" otherButton:nil informativeTextWithFormat:@"Sorry, LiveReload has gone horribly wrong. Please contact support and attach the latest events from your Console.app.\n\nIncident details:\n\n%@\n%@", subject, message] runModal];
    if (reply == NSAlertDefaultReturn) {
        TenderShowArticle(@"http://go.livereload.com/support/problem");
    } else {
        NSLog(@"Ignoring shit.");
    }
}
