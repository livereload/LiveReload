
#import "LRMessage.h"


@interface LRMessage ()

@end


@implementation LRMessage

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

@end
