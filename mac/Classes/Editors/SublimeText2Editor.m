
#import "SublimeText2Editor.h"

@implementation SublimeText2Editor

+ (Editor *)detectEditor {
    if ([[NSRunningApplication runningApplicationsWithBundleIdentifier:@"com.sublimetext.2"] count] > 0) {
        return [[[SublimeText2Editor alloc] init] autorelease];
    } else {
        return nil;
    }
}

+ (NSString *)editorDisplayName {
    return @"Sublime Text 2";
}

- (BOOL)jumpToFile:(NSString *)file line:(NSInteger)line {
    NSString *argument;
    if (line > 0) {
        argument = [NSString stringWithFormat:@"%@:%d", file, line];
    } else {
        argument = file;
    }

    NSString *subl = @"/Applications/Sublime Text 2.app/Contents/SharedSupport/bin/subl";
    if ([[NSFileManager defaultManager] fileExistsAtPath:subl]) {
        NSTask *task = [[[NSTask alloc] init] autorelease];
        [task setLaunchPath:subl];
        [task setArguments:[NSArray arrayWithObject:argument]];
        [task launch];
        return YES;
    }

    NSLog(@"Cannot find Sublime Text 2 command line tool at '%@'.", subl);
    return [[NSWorkspace sharedWorkspace] openFile:file withApplication:@"SubEthaEdit"];
}

@end
