
#import "ToolOutput.h"
#import "console.h"

#import "UserScript.h"
#import "ATSandboxing.h"
#import "OldFSMonitor.h"
#import "FixUnixPath.h"
#import "NSTask+OneLineTasksWithOutput.h"

#import "stringutil.h"


NSString *const UserScriptManagerScriptsDidChangeNotification = @"UserScriptManagerScriptsDidChangeNotification";
NSString *const UserScriptErrorDomain = @"com.livereload.LiveReload.UserScript";


@interface UserScript ()

- (id)initWithPath:(NSString *)path;

@end


@interface UserScriptManager () <FSMonitorDelegate>

@end


@implementation UserScript {
    NSString *_path;
}

- (id)initWithPath:(NSString *)path {
    self = [super init];
    if (self) {
        _path = [path copy];
    }
    return self;
}

- (NSString *)uniqueName {
    return [_path lastPathComponent];
}

- (NSString *)friendlyName {
    return [_path lastPathComponent];
}

- (NSString *)path {
    return _path;
}

- (BOOL)exists {
    return YES;
}

- (BOOL)invokeForProjectAtPath:(NSString *)projectPath withModifiedFiles:(NSSet *)paths output:(ToolOutput **)toolOutput error:(NSError **)err {
    if (toolOutput)
        *toolOutput = nil;
    if (err)
        *err = nil;
    
    NSString *script = _path;
    NSLog(@"Running post-processing script: %@", script);
    
    NSString *runDirectory = projectPath;
    NSArray *args = [paths allObjects];
    
    NSError *error = nil;
    NSString *pwd = [[NSFileManager defaultManager] currentDirectoryPath];
    [[NSFileManager defaultManager] changeCurrentDirectoryPath:runDirectory];
    const char *project_path = [projectPath UTF8String];
    console_printf("Post-proc exec: %s %s", str_collapse_paths([script UTF8String], [projectPath UTF8String]), str_collapse_paths([[args componentsJoinedByString:@" "] UTF8String], [projectPath UTF8String]));
    NSString *output = [NSTask stringByLaunchingPath:script
                                       withArguments:args
                                               error:&error];
    [[NSFileManager defaultManager] changeCurrentDirectoryPath:pwd];

    if (error) {
        NSLog(@"Error: %@\nOutput:\n%@", [error description], output);
        if ([error code] == kNSTaskProcessOutputError) {
            if (toolOutput)
                *toolOutput = [[ToolOutput alloc] initWithCompiler:nil type:ToolOutputTypeLog sourcePath:self.friendlyName line:0 message:nil output:output];
        }
        if (err)
            *err = error;
    }

    if ([output length] > 0) {
        console_printf("\n%s\n\n", str_collapse_paths([output UTF8String], project_path));
        NSLog(@"Post-processing output:\n%@\n", output);
    }
    if (error) {
        console_printf("Post-processor failed.");
        NSLog(@"Error: %@", [error description]);
    }
    return YES;
}

@end


@implementation MissingUserScript {
    NSString *_name;
}

- (id)initWithName:(NSString *)name {
    self = [super init];
    if (self) {
        _name = [name copy];
    }
    return self;
}

- (NSString *)uniqueName {
    return _name;
}

- (NSString *)friendlyName {
    return [NSString stringWithFormat:@"%@ (missing)", _name];
}

- (NSString *)path {
    return nil;
}

- (BOOL)exists {
    return NO;
}

- (BOOL)invokeForProjectAtPath:(NSString *)path withModifiedFiles:(NSSet *)paths output:(ToolOutput **)output error:(NSError **)error {
    if (error)
        *error = [NSError errorWithDomain:UserScriptErrorDomain code:UserScriptErrorMissingScript userInfo:nil];
    return NO;
}

@end


@implementation UserScriptManager {
    FSMonitor *_monitor;
}

static UserScriptManager *sharedUserScriptManager = nil;

+ (UserScriptManager *)sharedUserScriptManager {
    if (sharedUserScriptManager == nil) {
        sharedUserScriptManager = [[UserScriptManager alloc] init];
    }
    return sharedUserScriptManager;
}

- (id)init {
    self = [super init];
    if (self) {
        _monitor = [[FSMonitor alloc] initWithPath:ATUserScriptsDirectory()];
        _monitor.delegate = self;
        _monitor.running = YES;
    }
    return self;
}

- (NSArray *)userScripts {
    NSError *error = nil;
    NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:[NSURL fileURLWithPath:ATUserScriptsDirectory() isDirectory:YES] includingPropertiesForKeys:[NSArray array] options:NSDirectoryEnumerationSkipsHiddenFiles|NSDirectoryEnumerationSkipsPackageDescendants|NSDirectoryEnumerationSkipsSubdirectoryDescendants error:&error];
    
    NSMutableArray *result = [NSMutableArray array];
    for (NSURL *pathUrl in files) {
        [result addObject:[[[UserScript alloc] initWithPath:[pathUrl path]] autorelease]];
    }
    return result;
}

- (void)revealUserScriptsFolderSelectingScript:(UserScript *)selectedScript {
    NSString *path = ATUserScriptsDirectory();
    if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        NSError *error = nil;
        [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:[NSDictionary dictionary] error:&error];
        if (error) {
            [[NSAlert alertWithMessageText:@"You need to create a Scripts folder yourself" defaultButton:@"OK" alternateButton:@"No way!" otherButton:nil informativeTextWithFormat:@"Sorry, Mac OS X 10.7 cannot create a scripts folder automatically. This app cannot do it either because of the sandbox. Please create folder %@ yourself, and try again.", path] runModal];
            return;
        }
    }
    [[NSWorkspace sharedWorkspace] selectFile:selectedScript.path inFileViewerRootedAtPath:path];
}

- (void)fileSystemMonitor:(FSMonitor *)monitor detectedChangeAtPathes:(NSSet *)pathes {
    [[NSNotificationCenter defaultCenter] postNotificationName:UserScriptManagerScriptsDidChangeNotification object:self];
}

@end
