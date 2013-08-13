
#import "CustomCommandAction.h"
#import "ToolOutput.h"
#import "NSArray+ATSubstitutions.h"
#import "ATChildTask.h"


@implementation CustomCommandAction

+ (NSString *)typeIdentifier {
    return @"command";
}

- (void)loadFromMemento:(NSDictionary *)memento {
    [super loadFromMemento:memento];
    self.command = memento[@"command"] ?: @"";
}

- (void)updateMemento:(NSMutableDictionary *)memento {
    [super updateMemento:memento];
    memento[@"command"] = self.command;
}

- (void)setCommand:(NSString *)command {
    if (_command != command) {
        _command = command;
        [[NSNotificationCenter defaultCenter] postNotificationName:@"SomethingChanged" object:self];
    }
}

- (BOOL)isNonEmpty {
    return _command.length > 0;
}

+ (NSSet *)keyPathsForValuesAffectingNonEmpty {
    return [NSSet setWithObject:@"command"];
}

- (NSString *)singleLineCommand {
    return [_command stringByReplacingOccurrencesOfString:@"\n" withString:@"; "];
}

+ (NSSet *)keyPathsForValuesAffectingSingleLineCommand {
    return [NSSet setWithObject:@"command"];
}

//NSString *DetermineShell() {
//    NSString *userShell = [[[NSProcessInfo processInfo] environment] objectForKey:@"SHELL"];
//    NSLog(@"User's shell is %@", userShell);
//
//    // avoid executing stuff like /sbin/nologin as a shell
//    BOOL isValidShell = NO;
//    for (NSString *validShell in [[NSString stringWithContentsOfFile:@"/etc/shells" encoding:NSUTF8StringEncoding error:nil] componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]]) {
//        if ([[validShell stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] isEqualToString:userShell]) {
//            isValidShell = YES;
//            break;
//        }
//    }
//
//    if (!isValidShell) {
//        NSLog(@"Shell %@ is not in /etc/shells, won't continue.", userShell);
//        return nil;
//    }
//
//    return userShell;
//}


- (void)invokeForProjectAtPath:(NSString *)projectPath withModifiedFiles:(NSSet *)paths completionHandler:(UserScriptCompletionHandler)completionHandler {
    NSDictionary *info = @{
                           @"$(ruby)": @"/System/Library/Frameworks/Ruby.framework/Versions/Current/usr/bin/ruby",
                           @"$(node)": [[NSBundle mainBundle] pathForResource:@"LiveReloadNodejs" ofType:nil],
                           @"$(project_dir)": projectPath,
                           };
    NSString *command = [self.command stringBySubstitutingValuesFromDictionary:info];

    NSString *shell = @"/bin/bash"; //DetermineShell();

    //    NSArray *shArgs = @[@"--login", @"-i", @"-c", command];
    NSArray *shArgs = @[@"-c", command];

    NSString *pwd = [[NSFileManager defaultManager] currentDirectoryPath];
    [[NSFileManager defaultManager] changeCurrentDirectoryPath:projectPath];

    //    const char *project_path = [self.path UTF8String];
    //    console_printf("Post-proc exec: %s --login -c \"%s\"", [shell UTF8String], str_collapse_paths([command UTF8String], project_path));

    ATLaunchUnixTaskAndCaptureOutput([NSURL fileURLWithPath:shell], shArgs, ATLaunchUnixTaskAndCaptureOutputOptionsIgnoreSandbox|ATLaunchUnixTaskAndCaptureOutputOptionsMergeStdoutAndStderr, ^(NSString *outputText, NSString *stderrText, NSError *error) {
        [[NSFileManager defaultManager] changeCurrentDirectoryPath:pwd];
        ToolOutput *toolOutput = nil;

        if (error) {
            NSLog(@"Error: %@\nOutput:\n%@", [error description], outputText);
            toolOutput = [[ToolOutput alloc] initWithCompiler:nil type:ToolOutputTypeLog sourcePath:command line:0 message:nil output:outputText];
        }
        completionHandler(YES, toolOutput, error);
    });
}

@end
