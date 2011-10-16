
#import "CommunicationController.h"
#import "WebSocketServer.h"
#import "Project.h"
#import "Workspace.h"
#import "JSON.h"
#import "Preferences.h"

#import "NSDictionaryAndArray+SafeAccess.h"

#define PORT_NUMBER 35729

#define PROTOCOL_OFFICIAL_7 @"http://livereload.com/protocols/official-7"
#define PROTOCOL_CONNTEST_1 @"http://livereload.com/protocols/connection-check-1"

#define HANDSHAKE_TIMEOUT 1.0


static CommunicationController *sharedCommunicationController;

NSString *CommunicationStateChangedNotification = @"CommunicationStateChangedNotification";



@interface CommunicationController () <WebSocketServerDelegate, LiveReloadConnectionDelegate>

@end

@interface LiveReloadConnection () <WebSocketConnectionDelegate>

- (id)initWithConnection:(WebSocketConnection *)connection;
- (void)didFinishHandshake;

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

- (id)init {
    self = [super init];
    if (self) {
        _connections = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)startServer {
    _server = [[WebSocketServer alloc] init];
    _server.delegate = self;
    _server.port = PORT_NUMBER;
    [_server connect];
}

- (void)broadcastChangedPathes:(NSSet *)pathes inProject:(Project *)project {
    NSLog(@"Broadcasting change in %@: %@", project.path, [pathes description]);
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    for (NSString *path in pathes) {
        NSDictionary *command = [NSDictionary dictionaryWithObjectsAndKeys:@"reload", @"command",
                              path, @"path",
//                              [NSNumber numberWithBool:[[Preferences sharedPreferences] autoreloadJavascript]], @"liveJS",
                              [NSNumber numberWithBool:YES], @"liveCSS",
                              nil];
        [_server broadcast:[command JSONRepresentation]];
    }

    [pool drain];
    [self willChangeValueForKey:@"numberOfProcessedChanges"];
    ++_numberOfProcessedChanges;
    [self didChangeValueForKey:@"numberOfProcessedChanges"];
}

- (void)connectionDidFinishHandshake:(LiveReloadConnection *)connection {
    if (connection.monitoring) {
        [self willChangeValueForKey:@"numberOfSessions"];
        if (++_numberOfSessions == 1) {
            [self willChangeValueForKey:@"numberOfProcessedChanges"];
            _numberOfProcessedChanges = 0;
            [self didChangeValueForKey:@"numberOfProcessedChanges"];
        }
        [self didChangeValueForKey:@"numberOfSessions"];
        if (![Workspace sharedWorkspace].monitoringEnabled) {
            [Workspace sharedWorkspace].monitoringEnabled = YES;
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:CommunicationStateChangedNotification object:nil];
    }
}

- (void)connectionDidClose:(LiveReloadConnection *)connection {
    if (connection.monitoring) {
        [_connections removeObject:connection];

        [self willChangeValueForKey:@"numberOfSessions"];
        --_numberOfSessions;
        [self didChangeValueForKey:@"numberOfSessions"];

        if ([Workspace sharedWorkspace].monitoringEnabled && _numberOfSessions == 0) {
            [Workspace sharedWorkspace].monitoringEnabled = NO;
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:CommunicationStateChangedNotification object:nil];
    }
}

- (void)webSocketServer:(WebSocketServer *)server didAcceptConnection:(WebSocketConnection *)socketConnection {
    LiveReloadConnection *connection = [[[LiveReloadConnection alloc] initWithConnection:socketConnection] autorelease];
    connection.delegate = self;
    [_connections addObject:connection];
}

- (void)webSocketServerDidFailToInitialize:(WebSocketServer *)server {
    NSInteger result = [[NSAlert alertWithMessageText:@"Failed to start: port occupied" defaultButton:@"Quit" alternateButton:nil otherButton:@"More Info" informativeTextWithFormat:@"LiveReload cannot listen on port %d. You probably have another copy of LiveReload 2.x, a command-line LiveReload 1.x or an alternative tool like guard-livereload running.\n\nPlease quit any other live reloaders and rerun LiveReload.", PORT_NUMBER] runModal];
    if (result == NSAlertOtherReturn) {
        [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://help.livereload.com/kb/troubleshooting/failed-to-start-port-occupied"]];
    }
    [NSApp terminate:nil];
}

@end


@implementation LiveReloadConnection

@synthesize delegate=_delegate;
@synthesize monitoring=_monitoring;

- (id)initWithConnection:(WebSocketConnection *)connection {
    self = [super init];
    if (self) {
        _connection = [connection retain];
        _connection.delegate = self;

        [self performSelector:@selector(handshakeTimeout) withObject:nil afterDelay:HANDSHAKE_TIMEOUT];
    }
    return self;
}

- (void)dealloc {
    [_connection release], _connection = nil;
    [super dealloc];
}

- (void)sendCommand:(NSDictionary *)command {
    [_connection send:[command JSONRepresentation]];
}

- (void)handshakeTimeout {
    _monitoring = YES;
    _monitoringProtocolVersion = 6;

    static BOOL warningDisplayed = NO;
    if (!warningDisplayed) {
        warningDisplayed = YES;

        NSInteger reply = [[NSAlert alertWithMessageText:@"Update browser extensions" defaultButton:@"Update Now" alternateButton:@"Ignore" otherButton:nil informativeTextWithFormat:@"Update your browser extensions to version 2.0 to get advantage of many bug fixes, automatic reconnection, @import support, in-browser LESS.js support and more.\n\nBest part is: most of future improvements will NOT require you to update your extensions, so it's just this one time.\n\nThis prompt will appear once every time you launch LiveReload, until you upgrade."] runModal];
        if (reply == NSAlertDefaultReturn) {
            [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://help.livereload.com/kb/general-use/browser-extensions"]];
        }
    }

    [self didFinishHandshake];
}

- (void)didFinishHandshake {
    if (_monitoringProtocolVersion != 6) {
        NSMutableDictionary *command = [NSMutableDictionary dictionary];
        [command setObject:@"hello" forKey:@"command"];
        [command setObject:[NSArray arrayWithObjects:PROTOCOL_OFFICIAL_7, PROTOCOL_CONNTEST_1, nil] forKey:@"protocols"];
        [self sendCommand:command];
    } else {
        [_connection send:@"!!ver:1.6"];
    }

    _handshakeDone = YES;
    if (_monitoring) {
        NSLog(@"Successfully negotiated a monitoring protocol version %d", _monitoringProtocolVersion);
    } else {
        NSLog(@"Successfully negotiated a non-monitoring protocol");
    }
    [_delegate connectionDidFinishHandshake:self];
}

- (void)processCommandNamed:(NSString *)command data:(NSDictionary *)data {
    if (!_handshakeDone) {
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(handshakeTimeout) object:nil];

        if ([command isEqualToString:@"hello"]) {
            NSArray *protocols = [data safeArrayForKey:@"protocols"];
            BOOL accepted = NO;
            if ([protocols containsObject:PROTOCOL_OFFICIAL_7]) {
                _monitoring = YES;
                _monitoringProtocolVersion = 7;
                accepted = YES;
            }
            if ([protocols containsObject:PROTOCOL_CONNTEST_1]) {
                accepted = YES;
            }
            if (!accepted) {
                NSLog(@"Incoming connection offered no suitable protocols. Disconnecting.");
            } else {
                [self didFinishHandshake];
            }
        }
    } else {
        NSLog(@"Unexpected message received: %@", command);
    }
}

- (void)webSocketConnection:(WebSocketConnection *)connection didReceiveMessage:(NSString *)message {
    if ([message characterAtIndex:0] == '{') {
        id json = [message JSONValue];
        if ([json isKindOfClass:[NSDictionary class]]) {
            NSString *command = [json safeStringForKey:@"command"];
            if (command) {
                NSLog(@"Received command: %@", message);
                [self processCommandNamed:command data:json];
                return;
            }
        }
    }
    NSLog(@"Received unparsable message: %@", message);
}

- (void)webSocketConnectionDidClose:(WebSocketConnection *)connection {
    NSLog(@"Connection closed.");
    [_delegate connectionDidClose:self];
}

@end