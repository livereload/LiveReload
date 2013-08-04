
#import "Coda2Editor.h"
#import "EKJumpRequest.h"
#import "NSAppleScript+ATInvokeHandlerWithArguments.h"



static NSString *CodaJumpScript =
    @"on jump(charOffset)\n"
    @"  tell application \"Coda 2\"\n"
    @"    set selected range of selected split of selected tab of front window to {charOffset, 0}\n"
    @"  end tell\n"
    @"end jump\n";



@implementation Coda2Editor

- (id)init {
    self = [super init];
    if (self) {
        self.identifier = @"com.panic.Coda2";
        self.cocoaBundleId = @"com.panic.Coda2";
        self.displayName = @"Coda 2";
        self.defaultPriority = 3;
    }
    return self;
}

- (void)doUpdateStateInBackground {
    NSURL *url = [[NSWorkspace sharedWorkspace] URLForApplicationWithBundleIdentifier:self.cocoaBundleId];
    if (!url)
        return [self updateState:EKEditorStateNotFound error:nil];

    if ([[NSRunningApplication runningApplicationsWithBundleIdentifier:self.cocoaBundleId] count] > 0)
        return [self updateState:EKEditorStateRunning error:nil];

    [self updateState:EKEditorStateFound error:nil];
}

- (void)jumpWithRequest:(EKJumpRequest *)request completionHandler:(void(^)(NSError *error))completionHandler {
    if (![[NSWorkspace sharedWorkspace] openURLs:@[request.fileURL] withAppBundleIdentifier:self.cocoaBundleId options:0 additionalEventParamDescriptor:nil launchIdentifiers:NULL])
        return completionHandler([NSError errorWithDomain:EKErrorDomain code:EKErrorCodeLaunchFailed userInfo:nil]);

    if (request.line != EKJumpRequestValueUnknown) {
        NSError *error;
        int offset = [request computeLinearOffsetWithError:&error];
        if (offset == EKJumpRequestValueUnknown)
            return completionHandler([NSError errorWithDomain:EKErrorDomain code:EKErrorCodeJumpFailed userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"Failed to jump to line in Coda 2: cannot read file, error: %@", error.localizedDescription], NSUnderlyingErrorKey: error}]);

        NSAppleScript *appleScript = [[NSAppleScript alloc] initWithSource:CodaJumpScript];

        NSDictionary *errors = [NSDictionary dictionary];
        if (![appleScript executeHandlerNamed:@"jump" withArguments:@[[NSAppleEventDescriptor descriptorWithInt32:offset]] error:&errors])
            return completionHandler([NSError errorWithDomain:EKErrorDomain code:EKErrorCodeJumpFailed userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"Failed to jump to line in Coda 2: cannot read file, errors: %@", errors]}]);
    }

    return completionHandler(nil);
}

@end
