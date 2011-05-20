
#import <Foundation/Foundation.h>


@protocol WebSocketServerDelegate;
@protocol WebSocketConnectionDelegate;
@class WebSocketServer;
@class WebSocketConnection;


@interface WebSocketServer : NSObject {
    struct libwebsocket_context *context;
    NSUInteger port;
    __weak id<WebSocketServerDelegate> delegate;
}

@property(nonatomic) NSUInteger port;

@property(nonatomic, assign) __weak id<WebSocketServerDelegate> delegate;

- (void)connect;

- (void)broadcast:(NSString *)message;

- (NSInteger)countOfConnections;

@end


@protocol WebSocketServerDelegate <NSObject>

- (void)webSocketServer:(WebSocketServer *)server didAcceptConnection:(WebSocketConnection *)connection;

@end


@interface WebSocketConnection : NSObject {
    __weak WebSocketServer *server;
    struct libwebsocket *wsi;
    __weak id<WebSocketConnectionDelegate> delegate;
}

@property(nonatomic, assign, readonly) __weak WebSocketServer *server;
@property(nonatomic, assign) __weak id<WebSocketConnectionDelegate> delegate;

- (void)send:(NSString *)message;

@end


@protocol WebSocketConnectionDelegate <NSObject>

- (void)webSocketConnection:(WebSocketConnection *)connection didReceiveMessage:(NSString *)message;

- (void)webSocketConnectionDidClose:(WebSocketConnection *)connection;

@end
