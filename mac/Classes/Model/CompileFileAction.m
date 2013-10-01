
#import "CompileFileAction.h"
#import "Project.h"
#import "Plugin.h"
#import "LRFile2.h"
#import "NSArray+ATSubstitutions.h"
#import "ATChildTask.h"
#import "ToolOutput.h"

#include "console.h"
#include "stringutil.h"

@implementation CompileFileAction

- (NSString *)label {
    return self.type.name;
}

- (void)loadFromMemento:(NSDictionary *)memento {
    [super loadFromMemento:memento];
    self.compilerName = memento[@"compiler"];
//    self.intrinsicInputPathSpec = [ATPathSpec pathSpecWithString:@"*.css" syntaxOptions:ATPathSpecSyntaxFlavorExtended];
}

- (void)compileFile:(LRFile2 *)file inProject:(Project *)project completionHandler:(UserScriptCompletionHandler)completionHandler {
    NSLog(@"Compiling %@/%@", project.path, file.relativePath);
    NSDictionary *info = @{
                           @"$(ruby)": @"/System/Library/Frameworks/Ruby.framework/Versions/Current/usr/bin/ruby",
                           @"$(node)": [[NSBundle mainBundle] pathForResource:@"LiveReloadNodejs" ofType:nil],
                           @"$(plugin)": self.type.plugin.path,
                           @"$(additional)": @[],
                           @"$(src_file)": [file.relativePath lastPathComponent],
                           @"$(src_path)": file.absolutePath,
                           @"$(src_dir)": [file.absolutePath stringByDeletingLastPathComponent],
                           @"$(src_rel_path)": file.relativePath,
                           @"$(project_dir)": project.path,
                           };

    NSArray *cmdline = self.type.options[@"cmdline"];
    cmdline = [cmdline arrayBySubstitutingValuesFromDictionary:info];
    NSString *command = cmdline[0];
    NSArray *args = [cmdline subarrayWithRange:NSMakeRange(1, cmdline.count - 1)];

    //    NSString *pwd = [[NSFileManager defaultManager] currentDirectoryPath];
    //    [[NSFileManager defaultManager] changeCurrentDirectoryPath:projectPath];

    console_printf("Exec: %s", str_collapse_paths([[cmdline componentsJoinedByString:@" "] UTF8String], [project.path UTF8String]));

    ATLaunchUnixTaskAndCaptureOutput([NSURL fileURLWithPath:command], args, ATLaunchUnixTaskAndCaptureOutputOptionsIgnoreSandbox|ATLaunchUnixTaskAndCaptureOutputOptionsMergeStdoutAndStderr, ^(NSString *outputText, NSString *stderrText, NSError *error) {
        //        [[NSFileManager defaultManager] changeCurrentDirectoryPath:pwd];
        ToolOutput *toolOutput = nil;

        if (error) {
            NSLog(@"Error: %@\nOutput:\n%@", [error description], outputText);
            toolOutput = [[ToolOutput alloc] initWithCompiler:nil type:ToolOutputTypeLog sourcePath:command line:0 message:nil output:outputText];
        }
        completionHandler(YES, toolOutput, error);
    });
}

- (void)invokeForProjectAtPath:(NSString *)projectPath withModifiedFiles:(NSSet *)paths completionHandler:(UserScriptCompletionHandler)completionHandler {
}

@end
