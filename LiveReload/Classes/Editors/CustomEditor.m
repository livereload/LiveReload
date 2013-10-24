
#import "CustomEditor.h"
#import "RegexKitLite.h"

@implementation CustomEditor

+ (Editor *)detectEditor {
    if ([[NSFileManager defaultManager] fileExistsAtPath:[@"~/.livereload/edit" stringByExpandingTildeInPath]]) {
        return [[[CustomEditor alloc] init] autorelease];
    } else {
        return nil;
    }
}

+ (NSString *)editorDisplayName {
    NSString *script = [NSString stringWithContentsOfFile:[@"~/.livereload/edit" stringByExpandingTildeInPath] encoding:NSUTF8StringEncoding error:nil];
    NSArray *captures = [script captureComponentsMatchedByRegex:@"LR-editor-name:\\s*\"([^'\\n]+)\""];
    if ([captures count] > 0)
        return [captures objectAtIndex:1];
    else
        return @"custom editor";
}

- (BOOL)jumpToFile:(NSString *)file line:(NSInteger)line {
    NSTask *task = [[[NSTask alloc] init] autorelease];
    [task setLaunchPath:[@"~/.livereload/edit" stringByExpandingTildeInPath]];
    if (line > 0) {
        [task setArguments:[NSArray arrayWithObjects:file, [NSString stringWithFormat:@"%ld", (long)line], nil]];
    } else {
        [task setArguments:[NSArray arrayWithObject:file]];
    }
    [task launch];
    return YES;
}

@end
