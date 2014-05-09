
#import <Foundation/Foundation.h>


typedef enum : NSUInteger {
    LRMessageSeverityError = 1,
    LRMessageSeverityWarning,
} LRMessageSeverity;


@class Project;
@class LRFile2;


@interface LRMessage : NSObject

@property(nonatomic, readonly) Project *project;
@property(nonatomic, readonly) LRMessageSeverity severity;
@property(nonatomic, readonly) LRFile2 *file;
@property(nonatomic, readonly) NSInteger line;
@property(nonatomic, readonly) NSInteger column;
@property(nonatomic, copy, readonly) NSString *actionDescription;
@property(nonatomic, copy, readonly) NSString *text;
@property(nonatomic, copy, readonly) NSString *stack;
@property(nonatomic, copy, readonly) NSString *rawOutput;

@end
