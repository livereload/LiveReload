
#import <Foundation/Foundation.h>
#import "LRMessage.h"


@interface LRSelfTestMessageExpectation : NSObject

+ (instancetype)messageExpectationWithDictionary:(NSDictionary *)data severity:(LRMessageSeverity)severity;

- (instancetype)initWithSeverity:(LRMessageSeverity)severity text:(NSString *)text filePath:(NSString *)filePath line:(NSInteger)line column:(NSInteger)column;

@property(nonatomic, readonly) LRMessageSeverity severity;
@property(nonatomic, copy, readonly) NSString *text;

@property(nonatomic, readonly) NSString *filePath;
@property(nonatomic, readonly) NSInteger line;
@property(nonatomic, readonly) NSInteger column;

- (BOOL)matchesMessage:(LRMessage *)message;

@end
