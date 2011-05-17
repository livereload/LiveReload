
#import <Foundation/Foundation.h>


@class Project;
@class WebSocketServer;


@interface CommunicationController : NSObject {
    WebSocketServer *_server;
}

+ (CommunicationController *)sharedCommunicationController;

- (void)startServer;

- (void)broadcastChangedPathes:(NSSet *)pathes inProject:(Project *)project;

@end
