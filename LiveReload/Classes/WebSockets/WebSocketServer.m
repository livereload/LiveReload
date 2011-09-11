#import "WebSocketServer.h"
#include "libwebsockets.h"
#include "private-libwebsockets.h"


enum {
    PROTOCOL_HTTP = 0,
    PROTOCOL_WEB_SOCKET = 1
};


@interface WebSocketServer ()

- (void)connected:(WebSocketConnection *)connection;

@end

@interface WebSocketConnection ()

- (id)initWithWebSocketServer:(WebSocketServer *)aServer socket:(struct libwebsocket *)aWsi;

- (void)received:(NSString *)message;
- (void)closed;

@end



#define MAX_POLL_ELEMENTS 100
struct pollfd pollfds[100];
int count_pollfds = 0;


static WebSocketServer *lastWebSocketServer;


struct WebSocketServer_http_per_session_data {
    WebSocketConnection *connection;
};

struct WebSocketServer_per_session_data {
    WebSocketConnection *connection;
};

static int WebSocketServer_http_callback(struct libwebsocket_context * this,
                                    struct libwebsocket *wsi,
                                    enum libwebsocket_callback_reasons reason,
                                    void *user, void *in, size_t len) {
    //struct WebSocketServer_http_per_session_data *pss = user;
    char client_name[128];
    char client_ip[128];
    NSString *path;

    switch (reason) {
        case LWS_CALLBACK_HTTP:
            fprintf(stderr, "serving HTTP URI %s\n", (char *)in);

            if (in && strcmp(in, "/livereload.js") == 0) {
                path = [[NSBundle mainBundle] pathForResource:@"livereload.js" ofType:nil];
                NSCAssert(path != nil, @"File 'livereload.js' not found inside the bundle");
                libwebsockets_serve_http_file(wsi, [path fileSystemRepresentation], "text/javascript");
                break;
            }

            if (in && strcmp(in, "/favicon.ico") == 0) {
//                if (libwebsockets_serve_http_file(wsi,
//                                                  LOCAL_RESOURCE_PATH"/favicon.ico", "image/x-icon"))
//                    fprintf(stderr, "Failed to send favicon\n");
                break;
            }

            /* send the script... when it runs it'll start websockets */

            fprintf(stderr, "Failed to send HTTP file\n");
            break;

            /*
             * callback for confirming to continue with client IP appear in
             * protocol 0 callback since no websocket protocol has been agreed
             * yet.  You can just ignore this if you won't filter on client IP
             * since the default uhandled callback return is 0 meaning let the
             * connection continue.
             */

        case LWS_CALLBACK_FILTER_NETWORK_CONNECTION:

            libwebsockets_get_peer_addresses((int)(long)user, client_name,
                                             sizeof(client_name), client_ip, sizeof(client_ip));

            fprintf(stderr, "Received network connect from %s (%s)\n",
                    client_name, client_ip);

            /* if we returned non-zero from here, we kill the connection */
            break;

        default:
            break;
    }

    return 0;
}

static int WebSocketServer_callback(struct libwebsocket_context * this,
                                    struct libwebsocket *wsi,
                                    enum libwebsocket_callback_reasons reason,
                                    void *user, void *in, size_t len) {
    int n;
    struct WebSocketServer_per_session_data *pss = user;
    NSString *message;

    switch (reason) {

        case LWS_CALLBACK_ESTABLISHED:
            pss->connection = [[WebSocketConnection alloc] initWithWebSocketServer:lastWebSocketServer socket:wsi];
            [lastWebSocketServer performSelectorOnMainThread:@selector(connected:) withObject:pss->connection waitUntilDone:NO];
            break;

        case LWS_CALLBACK_BROADCAST:
            n = libwebsocket_write(wsi, in, len, LWS_WRITE_TEXT);
            if (n < 0) {
                fprintf(stderr, "ERROR writing to socket");
                return 1;
            }
            break;

        case LWS_CALLBACK_RECEIVE:
            message = [[[NSString alloc] initWithBytes:in length:len encoding:NSUTF8StringEncoding] autorelease];
            [pss->connection performSelectorOnMainThread:@selector(received:) withObject:message waitUntilDone:NO];
            break;

        case LWS_CALLBACK_CLOSED:
            [pss->connection closed];
            [pss->connection release];
            pss->connection = nil;

//        case LWS_CALLBACK_ADD_POLL_FD:
//            pollfds[count_pollfds].fd = (int)(long)user;
//            pollfds[count_pollfds].events = (int)len;
//            pollfds[count_pollfds++].revents = 0;
//            break;
//
//        case LWS_CALLBACK_DEL_POLL_FD:
//            for (n = 0; n < count_pollfds; n++)
//                if (pollfds[n].fd == (int)(long)user)
//                    while (n < count_pollfds) {
//                        pollfds[n] = pollfds[n + 1];
//                        n++;
//                    }
//            count_pollfds--;
//            break;
//
//        case LWS_CALLBACK_SET_MODE_POLL_FD:
//            for (n = 0; n < count_pollfds; n++)
//                if (pollfds[n].fd == (int)(long)user)
//                    pollfds[n].events |= (int)(long)len;
//            break;
//
//        case LWS_CALLBACK_CLEAR_MODE_POLL_FD:
//            for (n = 0; n < count_pollfds; n++)
//                if (pollfds[n].fd == (int)(long)user)
//                    pollfds[n].events &= ~(int)(long)len;
//            break;

        default:
            break;
    }

    return 0;
}



static struct libwebsocket_protocols protocols[] = {
    // my understanding is that protocol 0 is always used for HTTP;
    // the "http-only" string is designed to never match any incoming
    // web socket extension/procotol ID (the terminology is still beyond me),
    // so that this protocol is never used for web sockets
    { "http-only", WebSocketServer_http_callback, sizeof(struct WebSocketServer_http_per_session_data) },
    // my understanding is that NULL here means this entry matches any web sockets request
    { NULL, WebSocketServer_callback, sizeof(struct WebSocketServer_per_session_data) },
    { NULL, NULL, 0 }
};



@implementation WebSocketServer

@synthesize port;
@synthesize delegate;

- (void)connect {
    [lastWebSocketServer release];
    lastWebSocketServer = [self retain];

    [self performSelectorInBackground:@selector(runInBackgroundThread) withObject:nil];
}

- (void)broadcast:(NSString *)message {
    NSLog(@"Broadcasting: %@", message);
    NSUInteger len = 0;
    NSUInteger cb = [message maximumLengthOfBytesUsingEncoding:NSUTF8StringEncoding];
    unsigned char *data = malloc(LWS_SEND_BUFFER_PRE_PADDING + cb +LWS_SEND_BUFFER_POST_PADDING);
    unsigned char *buf = data + LWS_SEND_BUFFER_PRE_PADDING;
    [message getBytes:buf maxLength:cb usedLength:&len encoding:NSUTF8StringEncoding options:0 range:NSMakeRange(0, [message length]) remainingRange:NULL];

    // NOTE: this call is a multithreaded race condition, but we cross our fingers and hope for the best :P
    libwebsockets_broadcast(&protocols[PROTOCOL_WEB_SOCKET], buf, len);

    free(data);
}

- (void)connected:(WebSocketConnection *)connection {
    [self.delegate webSocketServer:self didAcceptConnection:connection];
}

- (NSInteger)countOfConnections {
    NSInteger result = 0;
    for (int n = 0; n < FD_HASHTABLE_MODULUS; n++) {
        for (int m = 0; m < context->fd_hashtable[n].length; m++) {
            struct libwebsocket *wsi = context->fd_hashtable[n].wsi[m];
            if (wsi->mode != LWS_CONNMODE_WS_SERVING)
                continue;
            ++result;
        }
    }
    return result;
}

- (void)runInBackgroundThread {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    int opts = 0;
    context = libwebsocket_create_context(port, NULL, protocols,                                          libwebsocket_internal_extensions, NULL, NULL, -1, -1, opts);
    if (context == NULL) {
        NSLog(@"libwebsocket init failed");
        if ([delegate respondsToSelector:@selector(webSocketServerDidFailToInitialize:)]) {
            [delegate performSelectorOnMainThread:@selector(webSocketServerDidFailToInitialize:) withObject:self waitUntilDone:NO];
        }
        return;
    }

    while (0 == libwebsocket_service(context, 1000*60*60*24))
        ;

//    while (1) {
//        int n = poll(pollfds, count_pollfds, 25);
//        if (n < 0)
//            goto done;
//
//        if (n)
//            for (n = 0; n < count_pollfds; n++) {
//                if (pollfds[n].revents) {
//                    libwebsocket_service_fd(context,
//                                            &pollfds[n]);
//                }
//            }
//    }

done:
    libwebsocket_context_destroy(context);
    [pool drain];
}

@end


@implementation WebSocketConnection

@synthesize server;
@synthesize delegate;

- (id)initWithWebSocketServer:(WebSocketServer *)aServer socket:(struct libwebsocket *)aWsi {
    if ((self = [super init])) {
        server = aServer;
        wsi = aWsi;
    }
    return self;
}

- (void)received:(NSString *)message {
    [self.delegate webSocketConnection:self didReceiveMessage:message];
}

- (void)closed {
    [self.delegate webSocketConnectionDidClose:self];
}

- (void)send:(NSString *)message {
    NSLog(@"Sending: %@", message);
    NSUInteger len = 0;
    NSUInteger cb = [message maximumLengthOfBytesUsingEncoding:NSUTF8StringEncoding];
    unsigned char *data = malloc(LWS_SEND_BUFFER_PRE_PADDING + cb +LWS_SEND_BUFFER_POST_PADDING);
    unsigned char *buf = data + LWS_SEND_BUFFER_PRE_PADDING;
    [message getBytes:buf maxLength:cb usedLength:&len encoding:NSUTF8StringEncoding options:0 range:NSMakeRange(0, [message length]) remainingRange:NULL];

    // NOTE: this call is a multithreaded race condition, but we cross our fingers and hope for the best :P
    libwebsocket_write(wsi, buf, len, LWS_WRITE_TEXT);

    free(data);
}

@end
