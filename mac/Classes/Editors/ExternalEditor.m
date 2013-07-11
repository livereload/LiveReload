
#import "ExternalEditor.h"
#import "PlainUnixTask.h"
#import "TaskOutputReader.h"
#import "Errors.h"


@interface ExternalEditor ()
@end

@implementation ExternalEditor

@synthesize scriptFileURL = _scriptFileURL;
@synthesize properties = _properties;

- (id)initWithScriptFileURL:(NSURL*)aScriptFileURL properties:(NSDictionary*)aProperties {
    self = [super init];
    if (self) {
        _scriptFileURL = [aScriptFileURL retain];
        _properties = [aProperties retain];
    }
    return self;
}

- (NSString *)displayName {
    return self.properties[@"editor-name"];
}

- (void)doUpdateStateInBackground {
    NSError *error;
    id task = CreateUserUnixTask(self.scriptFileURL, &error);
    if (!task) {
        [self updateState:EditorStateBroken error:error];
        return;
    }

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        TaskOutputReader *outputReader = [[TaskOutputReader alloc] init];
        [task setStandardOutput:outputReader.standardOutputPipe.fileHandleForWriting];
        [task setStandardError:outputReader.standardErrorPipe.fileHandleForWriting];
        [outputReader startReading];

        [task executeWithArguments:@[@"--check"] completionHandler:^(NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSString *output = outputReader.combinedOutputText;
                NSLog(@"--check complete, error = %@, output = %@", [error localizedDescription], output);

                if (error) {
                    [self updateState:EditorStateBroken error:error];
                    return;
                }

                NSArray *lines = [output componentsSeparatedByString:@"\n"];
                NSArray *header = [lines[0] componentsSeparatedByString:@" "];
                if (![header[0] isEqualToString:@"check"] || header.count != 2) {
                    [self updateState:EditorStateBroken error:[NSError errorWithDomain:LRErrorDomain code:LRErrorPluginApiViolation userInfo:@{NSLocalizedDescriptionKey: @"Editor --check first output line must read 'check some_state'"}]];
                    return;
                }

                NSString *secondLine = (lines.count > 1 ? lines[1] : @"");

                NSString *state = header[1];
                if ([state isEqualToString:@"found"])
                    [self updateState:EditorStateFound error:nil];
                else if ([state isEqualToString:@"running"])
                    [self updateState:EditorStateRunning error:nil];
                else if ([state isEqualToString:@"broken"])
                    [self updateState:EditorStateBroken error:[NSError errorWithDomain:LRErrorDomain code:LRErrorEditorPluginReturnedBrokenState userInfo:@{NSLocalizedDescriptionKey: secondLine}]];
                else if ([state isEqualToString:@"not-found"])
                    [self updateState:EditorStateNotFound error:nil];
                else
                    [self updateState:EditorStateBroken error:[NSError errorWithDomain:LRErrorDomain code:LRErrorPluginApiViolation userInfo:@{NSLocalizedDescriptionKey:[NSString stringWithFormat:@"Editor --check returned unknown state '%@'", state]}]];
            });
        }];
    });
}

@end
