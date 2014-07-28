
#import "SublimeText2Editor.h"
#import "EKJumpRequest.h"


@protocol SublimeText2RemoteProxy <NSObject>
- (void)remoteCommandLine:(NSData *)commandLine reqId:(int)reqId;
@end

static void WriteInt8(NSMutableData *data, unsigned char value) {
    [data appendBytes:&value length:1];
}
static void WriteInt32(NSMutableData *data, int value) {
    [data appendBytes:&value length:4];
}
static void WriteString(NSMutableData *data, NSString *string) {
    const char *raw = [string UTF8String];
    int len = (int)strlen(raw);
    WriteInt32(data, len);
    [data appendBytes:raw length:len];
}


@implementation SublimeText2Editor

- (id)init {
    self = [super init];
    if (self) {
        self.identifier = @"com.sublimetext.2";
        self.cocoaBundleId = @"com.sublimetext.2";
        self.displayName = @"Sublime Text 2";
        self.defaultPriority = 2;
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

    id<SublimeText2RemoteProxy> proxy = (id)[NSConnection rootProxyForConnectionWithRegisteredName:@"Sublime Text 2" host:nil];
    NSLog(@"proxy = %@", proxy);
    if (!proxy)
        return completionHandler([NSError errorWithDomain:EKErrorDomain code:EKErrorCodeJumpFailed userInfo:nil]);

    NSMutableData *data = [NSMutableData data];

    WriteInt32(data, 5); // format version number

    // files
    WriteInt32(data, 1);
    WriteString(data, [request componentsJoinedByString:@":"]);
    // projects
    WriteInt32(data, 0);
    // commands
    WriteInt32(data, 0);

    WriteInt8(data, 0); // --debug
    WriteInt8(data, 0); // --multiinstance
    WriteInt8(data, 0); // --new-window
    WriteInt8(data, 0); // --add
    WriteInt8(data, 0); // --wait
    WriteInt8(data, 0); // --help
    WriteInt8(data, 0); // --version

    [proxy remoteCommandLine:data reqId:0];

    return completionHandler(nil);
}

@end
