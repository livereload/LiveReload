
#import "CommunicationController.h"
#import "ExtensionsController.h"
#import "WebSocketServer.h"
#import "Project.h"
#import "Workspace.h"
#import "JSON.h"
#import "Preferences.h"
#import "Stats.h"

#import "VersionNumber.h"
#import "NSDictionaryAndArray+SafeAccess.h"

#define PORT_NUMBER 35729

#define PROTOCOL_OFFICIAL_7 @"http://livereload.com/protocols/official-7"
#define PROTOCOL_CONNTEST_1 @"http://livereload.com/protocols/connection-check-1"

#define HANDSHAKE_TIMEOUT 1.0

#include "communication.h"
#include "sglib.h"


static CommunicationController *sharedCommunicationController;

NSString *CommunicationStateChangedNotification = @"CommunicationStateChangedNotification";



@interface CommunicationController () <WebSocketServerDelegate, LiveReloadConnectionDelegate>

@end

@interface LiveReloadConnection () <WebSocketConnectionDelegate>

- (id)initWithConnection:(WebSocketConnection *)connection;
- (void)didFinishHandshake;

- (void)sendRequest:(reload_request_t *)request inProject:(Project *)project;

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
        if ([[NSUserDefaults standardUserDefaults] objectForKey:@"LRPortNumber"])
            _portNumber = [[NSUserDefaults standardUserDefaults] integerForKey:@"LRPortNumber"];
        else
            _portNumber = PORT_NUMBER;
    }
    return self;
}

- (void)startServer {
    _server = [[WebSocketServer alloc] init];
    _server.delegate = self;
    _server.port = _portNumber;
    [_server connect];
}

- (void)broadcast:(reload_session_t *)session {
    Project *project = (Project *)session->project;

    if (_connections.count > 0) {
        AppNewsKitGoodTimeToDeliverMessages();
    }

    NSLog(@"Broadcasting change in %@", project.path);
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    SGLIB_SORTED_LIST_MAP_ON_ELEMENTS(reload_request_t, session->first, request, next, {
        for (LiveReloadConnection *connection in _connections) {
            [connection sendRequest:request inProject:project];
        }
    });

    [pool drain];
    [self willChangeValueForKey:@"numberOfProcessedChanges"];
    ++_numberOfProcessedChanges;
    [self didChangeValueForKey:@"numberOfProcessedChanges"];
}

- (void)connectionDidFinishHandshake:(LiveReloadConnection *)connection {
    if (connection.monitoring) {
        [self willChangeValueForKey:@"numberOfSessions"];
        ++_numberOfSessions;
        [self didChangeValueForKey:@"numberOfSessions"];
        if (![Workspace sharedWorkspace].monitoringEnabled) {
            [Workspace sharedWorkspace].monitoringEnabled = YES;
        }
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(considerStoppingMonitoring) object:nil];
        [[NSNotificationCenter defaultCenter] postNotificationName:CommunicationStateChangedNotification object:nil];
    }
}

- (void)considerStoppingMonitoring {
    if ([Workspace sharedWorkspace].monitoringEnabled && _numberOfSessions == 0) {
        [Workspace sharedWorkspace].monitoringEnabled = NO;
    }
}

- (void)connectionDidClose:(LiveReloadConnection *)connection {
    if (connection.monitoring) {
        [_connections removeObject:connection];

        [self willChangeValueForKey:@"numberOfSessions"];
        --_numberOfSessions;
        [self didChangeValueForKey:@"numberOfSessions"];

        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(considerStoppingMonitoring) object:nil];
        [self performSelector:@selector(considerStoppingMonitoring) withObject:nil afterDelay:5.0];
        [[NSNotificationCenter defaultCenter] postNotificationName:CommunicationStateChangedNotification object:nil];
    }
}

- (void)webSocketServer:(WebSocketServer *)server didAcceptConnection:(WebSocketConnection *)socketConnection {
    LiveReloadConnection *connection = [[[LiveReloadConnection alloc] initWithConnection:socketConnection] autorelease];
    connection.delegate = self;
    [_connections addObject:connection];
}

- (void)webSocketServerDidFailToInitialize:(WebSocketServer *)server {
    NSInteger result = [[NSAlert alertWithMessageText:@"Failed to start: port occupied" defaultButton:@"Quit" alternateButton:nil otherButton:@"More Info" informativeTextWithFormat:@"LiveReload cannot listen on port %d. You probably have another copy of LiveReload 2.x, a command-line LiveReload 1.x or an alternative tool like guard-livereload running.\n\nPlease quit any other live reloaders and rerun LiveReload.", (int)_portNumber] runModal];
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

- (void)sendOldCommand:(NSString *)name data:(NSDictionary *)data {
    [_connection send:[[NSArray arrayWithObjects:name, data, nil] JSONRepresentation]];
}

- (void)handshakeTimeout {
    _monitoring = YES;
    _monitoringProtocolVersion = 6;
    [self didFinishHandshake];
}

- (void)displayProtocol6UpgradePrompt {
    static BOOL warningDisplayed = NO;
    if (!warningDisplayed) {
        warningDisplayed = YES;

        NSInteger reply = [[NSAlert alertWithMessageText:@"Update browser extensions" defaultButton:@"Update Now" alternateButton:@"Ignore" otherButton:nil informativeTextWithFormat:@"Update your browser extensions to version 2.0 to get advantage of many bug fixes, automatic reconnection, @import support, in-browser LESS.js support and more."] runModal];
        if (reply == NSAlertDefaultReturn) {
            [[ExtensionsController sharedExtensionsController] installExtension:self];
        }
    }
}

- (void)displayUpgradePromptForBrowser:(NSString *)browser extVersion:(NSString *)version {
    static NSMutableDictionary *promptsDisplayed = nil;

    if ([promptsDisplayed objectForKey:browser])
        return;

    NSDictionary *latestVersions = [NSDictionary dictionaryWithObjectsAndKeys:@"2.0.2", @"safari", @"2.0.2", @"chrome", @"2.0.2", @"firefox", nil];
    NSString *latestVersion = [latestVersions objectForKey:[browser lowercaseString]];
    if (VersionNumberFromNSString(version) < VersionNumberFromNSString(latestVersion)) {
        if (promptsDisplayed == nil)
            promptsDisplayed = [[NSMutableDictionary alloc] init];
        [promptsDisplayed setObject:latestVersion forKey:browser];

        NSInteger reply = [[NSAlert alertWithMessageText:@"Update browser extension" defaultButton:@"Update Now" alternateButton:@"Ignore" otherButton:nil informativeTextWithFormat:@"The latest version of %@ extension is %@, you currently have version %@. Please consider installing the new version.", browser, latestVersion, version] runModal];
        if (reply == NSAlertDefaultReturn) {
            ExtensionsController *ec = [ExtensionsController sharedExtensionsController];
            if ([browser isEqualToString:@"Safari"])
                [ec installSafariExtension:self];
            else if ([browser isEqualToString:@"Chrome"])
                [ec installChromeExtension:self];
            else if ([browser isEqualToString:@"Firefox"])
                [ec installFirefoxExtension:self];
            else
                [ec installExtension:self];
        }
    }
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
        NSLog(@"Successfully negotiated a monitoring protocol version %ld", _monitoringProtocolVersion);
    } else {
        NSLog(@"Successfully negotiated a non-monitoring protocol");
    }
    [_delegate connectionDidFinishHandshake:self];

    if (_monitoringProtocolVersion == 6) {
        [self displayProtocol6UpgradePrompt];
    } else if (_extensionName && _extensionVersion) {
        [self displayUpgradePromptForBrowser:_extensionName extVersion:_extensionVersion];
    }
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

                _extensionName = [[data safeStringForKey:@"ext"] copy];
                _extensionVersion = [[data safeStringForKey:@"extver"] copy];
                _snippetVersion = [[data safeStringForKey:@"snipver"] copy];
                _livereloadJsVersion = [[data safeStringForKey:@"ver"] copy];
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

 - (void)sendRequest:(reload_request_t *)request inProject:(Project *)project {
    if (_monitoring) {
        NSString *path = [NSString stringWithUTF8String:request->path];
        NSString *originalPath = (request->original_path ? [NSString stringWithUTF8String:request->original_path] : @"");

        if (_monitoringProtocolVersion < 7) {
            NSDictionary *data = [NSDictionary dictionaryWithObjectsAndKeys:
                                     path, @"path",
                                     //                              [NSNumber numberWithBool:[[Preferences sharedPreferences] autoreloadJavascript]], @"apply_js_live",
                                     [NSNumber numberWithBool:!project.disableLiveRefresh], @"apply_css_live",
                                     nil];
            [self sendOldCommand:@"refresh" data:data];
        } else {
            NSDictionary *command = [NSDictionary dictionaryWithObjectsAndKeys:@"reload", @"command",
                                     path, @"path",
                                     originalPath, @"originalPath",
                                     //                              [NSNumber numberWithBool:[[Preferences sharedPreferences] autoreloadJavascript]], @"liveJS",
                                     [NSNumber numberWithBool:!project.disableLiveRefresh], @"liveCSS",
                                     nil];
            [self sendCommand:command];
        }
    }
}

@end

void comm_broadcast_reload_requests(reload_session_t *session) {
    [[CommunicationController sharedCommunicationController] broadcast:session];
}
