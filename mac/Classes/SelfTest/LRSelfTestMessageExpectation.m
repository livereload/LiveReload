
#import "LRSelfTestMessageExpectation.h"
#import "LRSelfTestHelpers.h"


@interface LRSelfTestMessageExpectation ()

@end


@implementation LRSelfTestMessageExpectation

+ (instancetype)messageExpectationWithDictionary:(NSDictionary *)data severity:(LRMessageSeverity)severity {
    NSString *filePath = data[@"file"] ?: @"*";
    NSString *message = data[@"message"] ?: @"*";
    NSInteger line = [(data[@"line"] ?: @(-1)) integerValue];
    NSInteger column = [(data[@"column"] ?: @(-1)) integerValue];
    return [[self alloc] initWithSeverity:severity text:message filePath:filePath line:line column:column];
}

- (instancetype)initWithSeverity:(LRMessageSeverity)severity text:(NSString *)text filePath:(NSString *)filePath line:(NSInteger)line column:(NSInteger)column {
    self = [super init];
    if (self) {
        _severity = severity;
        _text = [text copy];
        _filePath = [filePath copy];
        _line = line;
        _column = column;
    }
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@ in %@:%d:%d: %@", (_severity == LRMessageSeverityError ? @"Error" : @"Warning"), _filePath, (int)_line, (int)_column, _text];
}

- (BOOL)matchesMessage:(LRMessage *)message {
    if (message.severity != _severity)
        return NO;
    if (!LRSelfTestMatchPath(_filePath, message.filePath))
        return NO;
    if (!LRSelfTestMatchUnsignedInteger(_line, message.line))
        return NO;
    if (!LRSelfTestMatchUnsignedInteger(_column, message.column))
        return NO;
    if (!LRSelfTestMatchString(_text, message.text))
        return NO;
    return YES;
}

@end
