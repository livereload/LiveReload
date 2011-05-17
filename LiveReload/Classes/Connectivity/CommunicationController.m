
#import "CommunicationController.h"
#import "WebSocketServer.h"
#import "Project.h"
#import "JSON.h"


static CommunicationController *sharedCommunicationController;


@interface CommunicationController () <WebSocketServerDelegate, WebSocketConnectionDelegate>

@end


@implementation CommunicationController

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
}

- (void)webSocketServer:(WebSocketServer *)server didAcceptConnection:(WebSocketConnection *)connection {
    NSLog(@"Accepted connection.");
    connection.delegate = self;
    [connection send:@"!!ver:1.6"];
}

- (void)webSocketConnection:(WebSocketConnection *)connection didReceiveMessage:(NSString *)message {
    NSLog(@"Received: %@", message);
}

- (void)webSocketConnectionDidClose:(WebSocketConnection *)connection {
    NSLog(@"Connection closed.");
}

@end
