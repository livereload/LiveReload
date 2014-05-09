
#import <Foundation/Foundation.h>


@interface LROperationResult : NSObject

@property (nonatomic, readonly, getter = isCompleted) BOOL completed;

// either an error message is logged, or an error is indicated by the exit code
@property (nonatomic, readonly, getter = isFailed) BOOL failed;

// error indicated by the exit code, but no error messages detected
@property (nonatomic, readonly, getter = hasParsingFailed) BOOL parsingFailed;

@property (nonatomic, copy, readonly) NSArray *messages;
@property (nonatomic, copy, readonly) NSArray *errors;
@property (nonatomic, copy, readonly) NSArray *warnings;

@property (nonatomic, copy, readonly) NSString *rawOutput;

@end
