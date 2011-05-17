
#import <Foundation/Foundation.h>


@class Project;


@interface CommunicationController : NSObject {

}

+ (CommunicationController *)sharedCommunicationController;

- (void)broadcastChangedPathes:(NSSet *)pathes inProject:(Project *)project;

@end
