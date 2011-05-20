
#import "CommunicationController.h"
#import "WebSocketServer.h"
#import "Project.h"
#import "Workspace.h"
#import "JSON.h"


static CommunicationController *sharedCommunicationController;

NSString *CommunicationStateChangedNotification = @"CommunicationStateChangedNotification";



@interface CommunicationController () <WebSocketServerDelegate, WebSocketConnectionDelegate>

@end


@implementation CommunicationController

@synthesize numberOfSessions=_numberOfSessions;
@synthesize numberOfProcessedChanges=_numberOfProcessedChanges;

+ (CommunicationController *)sharedCommunicationController {
    if (sharedCommunicationController == nil) {
        sharedCommunicationController = [[CommunicationController alloc] init];
    }
    return sharedCommunicationController;
}

- (void)startServer {
    _server = [[WebSocketServer alloc] init];
    _server.delegate = self;
    _server.port = 35729;
    [_server connect];
}

- (void)broadcastChangedPathes:(NSSet *)pathes inProject:(Project *)project {
    NSLog(@"Broadcasting change in %@: %@", project.path, [pathes description]);
    for (NSString *path in pathes) {
        NSDictionary *args = [NSDictionary dictionaryWithObjectsAndKeys:path, @"path",
                              [NSNumber numberWithBool:NO], @"apply_js_live",
                              [NSNumber numberWithBool:YES], @"apply_css_live",
                              nil];
        NSArray *command = [NSArray arrayWithObjects:@"refresh", args, nil];
        [_server broadcast:[command JSONRepresentation]];
    }

    [self willChangeValueForKey:@"numberOfProcessedChanges"];
    ++_numberOfProcessedChanges;
    [self didChangeValueForKey:@"numberOfProcessedChanges"];
}

- (void)webSocketServer:(WebSocketServer *)server didAcceptConnection:(WebSocketConnection *)connection {
    if (++_numberOfSessions == 1) {
        [self willChangeValueForKey:@"numberOfProcessedChanges"];
        _numberOfProcessedChanges = 0;
        [self didChangeValueForKey:@"numberOfProcessedChanges"];
    }
    NSLog(@"Accepted connection.");
    connection.delegate = self;
    [connection send:@"!!ver:1.6"];
    if (![Workspace sharedWorkspace].monitoringEnabled) {
        [Workspace sharedWorkspace].monitoringEnabled = YES;
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:CommunicationStateChangedNotification object:nil];
}

- (void)webSocketConnection:(WebSocketConnection *)connection didReceiveMessage:(NSString *)message {
    NSLog(@"Received: %@", message);
}

- (void)webSocketConnectionDidClose:(WebSocketConnection *)connection {
    --_numberOfSessions;
    NSLog(@"Connection closed.");
    if ([Workspace sharedWorkspace].monitoringEnabled && [connection.server countOfConnections] == 0) {
        [Workspace sharedWorkspace].monitoringEnabled = NO;
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:CommunicationStateChangedNotification object:nil];
}

@end
