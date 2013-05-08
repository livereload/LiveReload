
#import <Foundation/Foundation.h>


@interface TaskOutputReader : NSObject

- (id)init;
- (id)initWithTask:(id)task;

@property(strong, readonly) NSPipe *standardOutputPipe;
@property(strong, readonly) NSPipe *standardErrorPipe;

@property(strong, readonly) NSData *standardOutputData;
@property(strong, readonly) NSData *standardErrorData;

@property(strong, readonly) NSString *standardOutputText;
@property(strong, readonly) NSString *standardErrorText;
@property(strong, readonly) NSString *combinedOutputText;

- (void)startReading;

@end
