
#import "LROperationResult.h"
#import "LiveReload-Swift-x.h"

#import "ATFunctionalStyle.h"
#import "Glue.h"
@import LRCommons;


@interface LROperationResult ()

@end


@implementation LROperationResult {
    NSMutableString *_rawOutput;
    NSMutableArray *_messages;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _rawOutput = [NSMutableString new];
        _messages = [NSMutableArray new];
    }
    return self;
}

- (BOOL)hasParsingFailed {
    return self.failed && _rawOutput.length > 0 && self.errors.count == 0;
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

- (void)addMessage:(LRMessage *)message {
    if (message.severity == LRMessageSeverityError) {
        _failed = YES;
    }
    [_messages addObject:message];
}

- (void)completedWithInvocationError:(NSError *)error {
    _completed = YES;

    if (error) {
        _failed = YES;
    }

    if (_failed && _messages.count == 0) {
        if (_rawOutput.length > 0) {
            LRMessage *message = [[LRMessage alloc] initWithSeverity:LRMessageSeverityError text:_rawOutput filePath:_defaultMessageFile.absolutePath line:0 column:0];
            message.rawOutput = _rawOutput;
            [self addMessage:message];
        } else {
            LRMessage *message = [[LRMessage alloc] initWithSeverity:LRMessageSeverityError text:[NSString stringWithFormat:NSLocalizedString(@"Cannot launch compiler: %@", @"User-visible error message when the compiler fails and the output is empty"), error.localizedDescription] filePath:_defaultMessageFile.absolutePath line:0 column:0];
            [self addMessage:message];
        }
    }

    _invocationError = error;
}

- (void)addRawOutput:(NSString *)rawOutput withCompletionBlock:(dispatch_block_t)completionBlock {
    [_rawOutput appendString:rawOutput];

    if (rawOutput.length > 0 && !!_errorSyntaxManifest) {
        [[Glue glue] postMessage:@{@"service": @"msgparser", @"command": @"parse", @"manifest": _errorSyntaxManifest, @"input": rawOutput} withReplyHandler:^(NSError *error, NSDictionary *response) {
            for (NSDictionary *message in response[@"messages"]) {
                NSString *type = message[@"type"];
                LRMessageSeverity severity = ([type isEqualToString:@"error"] ? LRMessageSeverityError : LRMessageSeverityWarning);
                NSString *text = message[@"message"];
                NSString *affectedFilePath = message[@"file"] ?: _defaultMessageFile.absolutePath;
                NSInteger line = [message[@"line"] integerValue];
                NSInteger column = [message[@"column"] integerValue];
                LRMessage *message = [[LRMessage alloc] initWithSeverity:severity text:text filePath:affectedFilePath line:line column:column];
                [self addMessage:message];
            }
            completionBlock();
        }];
    } else {
        completionBlock();
    }
}

- (void)completedWithInvocationError:(NSError *)error rawOutput:(NSString *)rawOutput completionBlock:(dispatch_block_t)completionBlock {
    P2DisableARCRetainCyclesWarning();
    [self addRawOutput:rawOutput withCompletionBlock:^{
        [self completedWithInvocationError:error];
        completionBlock();
    }];
    P2ReenableWarning();
}

@end
