
#import "BBEditEditor.h"

@implementation BBEditEditor

+ (Editor *)detectEditor {
    if ([[NSRunningApplication runningApplicationsWithBundleIdentifier:@"com.barebones.bbedit"] count] > 0) {
        return [[[BBEditEditor alloc] init] autorelease];
    } else {
        return nil;
    }
}

+ (NSString *)editorDisplayName {
    return @"BBEdit";
}

- (BOOL)jumpToFile:(NSString *)file line:(NSInteger)line {
    NSString *argument;
    if (line > 0) {
        argument = [NSString stringWithFormat:@"%@:%ld", file, (long)line];
    } else {
        argument = file;
    }

    NSString *subl = @"/usr/local/bin/bbedit";
    if ([[NSFileManager defaultManager] fileExistsAtPath:subl]) {
        NSTask *task = [[[NSTask alloc] init] autorelease];
        [task setLaunchPath:subl];
        [task setArguments:[NSArray arrayWithObject:argument]];
        [task launch];
        return YES;
    }

    NSLog(@"Cannot find BBEdit command line tool at '%@'.", subl);
    return [[NSWorkspace sharedWorkspace] openFile:file withApplication:@"BBEdit"];
}

@end
