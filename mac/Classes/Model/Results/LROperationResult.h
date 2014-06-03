
#import <Foundation/Foundation.h>


@class LRMessage;
@class LRProjectFile;


@interface LROperationResult : NSObject

@property (nonatomic, readonly, getter = isCompleted) BOOL completed;

// either an error message is logged, or an error is indicated by the exit code
@property (nonatomic, readonly, getter = isFailed) BOOL failed;

@property (nonatomic, readonly) NSError *invocationError;

// error indicated by the exit code, but no error messages detected
@property (nonatomic, readonly, getter = hasParsingFailed) BOOL parsingFailed;

@property (nonatomic, copy, readonly) NSArray *messages;
@property (nonatomic, copy, readonly) NSArray *errors;
@property (nonatomic, copy, readonly) NSArray *warnings;

@property (nonatomic, copy, readonly) NSString *rawOutput;

// default file for parsing messages
@property (nonatomic) LRProjectFile *defaultMessageFile;
@property (nonatomic, copy) NSDictionary *errorSyntaxManifest;

- (void)addMessage:(LRMessage *)message;
- (void)completedWithInvocationError:(NSError *)error;

// set errorSyntaxManifest to parse
- (void)addRawOutput:(NSString *)rawOutput withCompletionBlock:(dispatch_block_t)completionBlock;

- (void)completedWithInvocationError:(NSError *)error rawOutput:(NSString *)rawOutput completionBlock:(dispatch_block_t)completionBlock;

@end
