
#import "SubEthaEditEditor.h"

@implementation SubEthaEditEditor

+ (Editor *)detectEditor {
    if ([[NSRunningApplication runningApplicationsWithBundleIdentifier:@"de.codingmonkeys.SubEthaEdit"] count] > 0) {
        return [[[SubEthaEditEditor alloc] init] autorelease];
    } else {
        return nil;
    }
}

+ (NSString *)editorDisplayName {
    return @"SubEthaEdit";
}

- (BOOL)jumpToFile:(NSString *)file line:(NSInteger)line {
    if (line > 0) {
        NSString *see = @"/usr/bin/see";
        // TODO (could be useful): http://tech.groups.yahoo.com/group/SubEthaEdit/message/103
        if ([[NSFileManager defaultManager] fileExistsAtPath:see]) {
            NSTask *task = [[[NSTask alloc] init] autorelease];
            [task setLaunchPath:see];
            [task setArguments:[NSArray arrayWithObjects:@"-g", [NSString stringWithFormat:@"%d", line], file, nil]];
            [task launch];
            return YES;
        }
    }
    return [[NSWorkspace sharedWorkspace] openFile:file withApplication:@"SubEthaEdit"];
}

@end
