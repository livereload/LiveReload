
#import "TextMateEditor.h"

@implementation TextMateEditor

+ (Editor *)detectEditor {
    if ([[NSRunningApplication runningApplicationsWithBundleIdentifier:@"com.macromates.textmate"] count] > 0) {
        return [[[TextMateEditor alloc] init] autorelease];
    } else {
        return nil;
    }
}

+ (NSString *)editorDisplayName {
    return @"TextMate";
}

- (BOOL)jumpToFile:(NSString *)file line:(NSInteger)line {
    NSString *url;
    if (line > 0)
        url = [NSString stringWithFormat:@"txmt://open/?url=file://%@&line=%d", [file stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding], line];
    else
        url = [NSString stringWithFormat:@"txmt://open/?url=file://%@", [file stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:url]];
    return YES;
}

@end
