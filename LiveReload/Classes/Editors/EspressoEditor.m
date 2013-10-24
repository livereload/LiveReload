
#import "EspressoEditor.h"
#import <ApplicationServices/ApplicationServices.h>

enum {
    kVK_Command                   = 0x37,
    kVK_Shift                     = 0x38,
    kVK_Return                    = 0x24,
    kVK_ANSI_L                    = 0x25,
    kVK_ANSI_1                    = 0x12,
    kVK_ANSI_2                    = 0x13,
    kVK_ANSI_3                    = 0x14,
    kVK_ANSI_4                    = 0x15,
    kVK_ANSI_6                    = 0x16,
    kVK_ANSI_5                    = 0x17,
    kVK_ANSI_9                    = 0x19,
    kVK_ANSI_7                    = 0x1A,
    kVK_ANSI_8                    = 0x1C,
    kVK_ANSI_0                    = 0x1D,
};

static CGKeyCode DIGITS[] = { kVK_ANSI_0, kVK_ANSI_1, kVK_ANSI_2, kVK_ANSI_3, kVK_ANSI_4, kVK_ANSI_5, kVK_ANSI_6, kVK_ANSI_7, kVK_ANSI_8, kVK_ANSI_9 };


@implementation EspressoEditor

+ (Editor *)detectEditor {
    if ([[NSRunningApplication runningApplicationsWithBundleIdentifier:@"com.macrabbit.Espresso"] count] > 0) {
        return [[[EspressoEditor alloc] init] autorelease];
    } else {
        return nil;
    }
}

+ (NSString *)editorDisplayName {
    return @"Espresso";
}

- (BOOL)jumpToFile:(NSString *)file line:(NSInteger)line {
    if (![[NSWorkspace sharedWorkspace] openFile:file withApplication:@"Espresso"])
        return NO;

    if (line > 0) {
        void(^block)(void) = ^(void){
            NSDictionary *activeApp = [[NSWorkspace sharedWorkspace] activeApplication];
            if ([[activeApp objectForKey:@"NSApplicationBundleIdentifier"] isEqualToString:@"com.macrabbit.Espresso"]) {

                // workaround for a possible OS X bug, see http://stackoverflow.com/questions/2008126/cgeventpost-possible-bug-when-simulating-keyboard-events
                // don't post key down for modifiers

                NSLog(@"Posting events!");
                ProcessSerialNumber psn = { [[activeApp objectForKey:@"NSApplicationProcessSerialNumberHigh"] unsignedIntValue], [[activeApp objectForKey:@"NSApplicationProcessSerialNumberLow"] unsignedIntValue] };
                CGEventSourceRef source = CGEventSourceCreate(kCGEventSourceStateHIDSystemState);
                CGEventRef event;
                //                event = CGEventCreateKeyboardEvent(source, kVK_Command, YES);
                //                CGEventPostToPSN(&psn, event);
                event = CGEventCreateKeyboardEvent(source, kVK_ANSI_L, YES);
                CGEventSetFlags(event, kCGEventFlagMaskCommand);
                CGEventPostToPSN(&psn, event);
                CFRelease(event);
                event = CGEventCreateKeyboardEvent(source, kVK_ANSI_L, NO);
                CGEventPostToPSN(&psn, event);
                CFRelease(event);
                event = CGEventCreateKeyboardEvent(source, kVK_Command, NO);
                CGEventPostToPSN(&psn, event);
                CFRelease(event);

                NSString *digits = [NSString stringWithFormat:@"%ld", (long)line];
                for (int i = 0; i < [digits length]; i++) {
                    int digit = [digits characterAtIndex:i] - '0';
                    CGKeyCode keyCode = DIGITS[digit];
                    event = CGEventCreateKeyboardEvent(source, keyCode, YES);
                    CGEventPostToPSN(&psn, event);
                    CFRelease(event);
                    event = CGEventCreateKeyboardEvent(source, keyCode, NO);
                    CGEventPostToPSN(&psn, event);
                    CFRelease(event);
                }

                event = CGEventCreateKeyboardEvent(source, kVK_Return, YES);
                CGEventPostToPSN(&psn, event);
                CFRelease(event);
                event = CGEventCreateKeyboardEvent(source, kVK_Return, NO);
                CGEventPostToPSN(&psn, event);
                CFRelease(event);

                CFRelease(source);
            }

        };

        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.05 * NSEC_PER_SEC), dispatch_get_main_queue(), block);
    }

    return YES;
}

@end
