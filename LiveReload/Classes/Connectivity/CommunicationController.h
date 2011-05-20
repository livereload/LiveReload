
#import <Foundation/Foundation.h>


@class Project;
@class WebSocketServer;

extern NSString *CommunicationStateChangedNotification;


@interface CommunicationController : NSObject {
    WebSocketServer *_server;
    NSInteger _numberOfSessions;
    NSInteger _numberOfProcessedChanges;
}

+ (CommunicationController *)sharedCommunicationController;

@property(nonatomic, readonly) NSInteger numberOfSessions;

@property(nonatomic, readonly) NSInteger numberOfProcessedChanges;

- (void)startServer;

- (void)broadcastChangedPathes:(NSSet *)pathes inProject:(Project *)project;

@end
