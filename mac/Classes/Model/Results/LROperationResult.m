
#import "LROperationResult.h"
#import "LRMessage.h"

#import "ATFunctionalStyle.h"


@interface LROperationResult ()

@end


@implementation LROperationResult

- (BOOL)hasParsingFailed {
    return self.failed && self.errors.count == 0;
}

- (NSArray *)errors {
    return [self.messages filteredArrayUsingBlock:^BOOL(LRMessage *message) {
        return message.severity == LRMessageSeverityError;
    }];
}

- (NSArray *)warnings {
    return [self.messages filteredArrayUsingBlock:^BOOL(LRMessage *message) {
        return message.severity == LRMessageSeverityWarning;
    }];
}

@end
