
#import <Foundation/Foundation.h>


typedef enum : NSUInteger {
    LRMessageSeverityError = 1,
    LRMessageSeverityWarning,
} LRMessageSeverity;


@class LRProjectFile;


@interface LRMessage : NSObject

- (instancetype)initWithSeverity:(LRMessageSeverity)severity text:(NSString *)text filePath:(NSString *)filePath line:(NSInteger)line column:(NSInteger)column;

@property(nonatomic, readonly) LRMessageSeverity severity;
@property(nonatomic, copy, readonly) NSString *text;

//@property(nonatomic, readonly) LRFile2 *file;
@property(nonatomic, readonly) NSString *filePath;
@property(nonatomic, readonly) NSInteger line;
@property(nonatomic, readonly) NSInteger column;

@property(nonatomic, copy) NSString *stack;
@property(nonatomic, copy) NSString *rawOutput;

@end
