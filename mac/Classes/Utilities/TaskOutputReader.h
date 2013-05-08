
#import <Foundation/Foundation.h>


@interface TaskOutputReader : NSObject

@property(strong, readonly) NSPipe *standardOutputPipe;
@property(strong, readonly) NSPipe *standardErrorPipe;

@property(strong, readonly) NSData *standardOutputData;
@property(strong, readonly) NSData *standardErrorData;

@property(strong, readonly) NSString *standardOutputText;
@property(strong, readonly) NSString *standardErrorText;

- (void)startReading;

@end
