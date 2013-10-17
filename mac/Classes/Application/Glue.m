
#import "Glue.h"
#include "nodeapp_private.h"
#include "nodeapp_rpc_router.h"


void nodeapp_rpc_send_init(void *dummy) {
//    [[Glue glue] postMessage:@{
//        @"resourcesDir": [NSString stringWithUTF8String:nodeapp_bundled_resources_dir],
//        @"appDataDir": [NSString stringWithUTF8String:nodeapp_appdata_dir],
//        @"logDir": [NSString stringWithUTF8String:nodeapp_log_dir],
//        @"logFile": [NSString stringWithUTF8String:nodeapp_log_file],
//        @"version": @"" NODEAPP_VERSION,
//#if defined(APPSTORE)
//        @"build": @"appstore",
//#else
//        @"build": @"trial",
//#endif
//        @"platform": @"mac",
//    }];

    [[Glue glue] postMessage:@{
        @"service": @"server",
        @"command": @"init",
        @"appVersion": @"" NODEAPP_VERSION,
    }];
}


@implementation Glue {
    NSInteger _nextCallbackId;
    NSMutableDictionary *_callbackIdsToBlocks;    // NSString => GlueResultBlock
    NSMutableDictionary *_commandsToHandlers;     // NSString => GlueAsyncCommandBlock
}

+ (Glue *)glue {
    static Glue *glue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        glue = [Glue new];
    });
    return glue;
}

- (id)init {
    self = [super init];
    if (self) {
        _callbackIdsToBlocks = [NSMutableDictionary new];
        _commandsToHandlers = [NSMutableDictionary new];
        _nextCallbackId = 1;
    }
    return self;
}


#pragma mark - Sending messages

- (void)postMessage:(NSDictionary *)message {
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:message options:0 error:NULL];
    NSString *jsonString = [[[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding] stringByAppendingString:@"\n"];
    nodeapp_rpc_send_raw([jsonString UTF8String]);
}

- (void)postMessage:(NSDictionary *)message withReplyHandler:(GlueReplyHandlerBlock)block {
    NSMutableDictionary *fullMessage = [message mutableCopy];
    fullMessage[@"reply"] = @{@"callback": [self _registerCallback:block]};
    [self postMessage:fullMessage];
}

- (id)_registerCallback:(GlueReplyHandlerBlock)block {
    NSInteger callbackId = _nextCallbackId++;
    id callbackIdObj = @(callbackId);
    _callbackIdsToBlocks[callbackIdObj] = block;
    return callbackIdObj;
}


#pragma mark - Handler registration

- (void)registerCommand:(NSString *)command asyncHandler:(GlueAsyncCommandBlock)block {
    _commandsToHandlers[command] = block;
}

- (void)registerCommand:(NSString *)command syncHandler:(GlueSyncCommandBlock)block {
    [self registerCommand:command asyncHandler:^(NSDictionary *message, GlueReplyBlock reply) {
        NSError * __autoreleasing error = nil;
        block(message, &error);
        reply(error, nil);
    }];
}

- (void)registerCommand:(NSString *)command target:(id)object action:(SEL)action {
    NSMethodSignature *signature = [object methodSignatureForSelector:action];

    NSAssert(signature.numberOfArguments >= 2, @"Objective-C methods should have at least two arguments: self and _cmd!");
    switch (signature.numberOfArguments) {
        case 3: {
            [self registerCommand:command asyncHandler:^(NSDictionary *message, GlueReplyBlock reply) {
                [object performSelector:action withObject:message];
                reply(nil, nil);
            }];
            break;
        }
        case 4: {
            [self registerCommand:command asyncHandler:^(NSDictionary *message, GlueReplyBlock reply) {
                [object performSelector:action withObject:message withObject:reply];
            }];
            break;
        }
        default:
            [NSException raise:NSInternalInconsistencyException format:@"Registered command handler method must accept 1 or 2 arguments"];
            break;
    }
}


#pragma mark - Receiving messages

- (void)handleJsonString:(NSString *)line {
    NSLog(@"Glue: Received: '%@'", line);

    NSError * __autoreleasing error;
    NSData *incomingData = [line dataUsingEncoding:NSUTF8StringEncoding];
    id incomingObject = [NSJSONSerialization JSONObjectWithData:incomingData options:0 error:&error];
    if (!incomingObject) {
        NSLog(@"Glue: Cannot parse received line as JSON: %@ - %ld - %@", error.domain, (long)error.code, error.localizedDescription);
        return;
    }

    if (![incomingObject isKindOfClass:[NSDictionary class]]) {
        NSLog(@"Glue: Incoming JSON is not a dictionary.");
        return;
    }

    [self handleMessage:incomingObject];
}

- (void)handleMessage:(NSDictionary *)message {
    id callbackIdObj = message[@"callback"];
    if (callbackIdObj) {
        GlueReplyHandlerBlock block = _callbackIdsToBlocks[callbackIdObj];
        if (block) {
            [_callbackIdsToBlocks removeObjectForKey:callbackIdObj];

            id errorObj = message[@"error"];
            NSError *error = nil;
            if (errorObj) {
                error = [NSError errorWithDomain:@"Glue" code:1 userInfo:@{NSLocalizedDescriptionKey:[NSString stringWithFormat:@"Invocation error: %@ / %@", errorObj[@"code"], errorObj[@"message"]]}];
            }
            block(error, message[@"result"]);
        } else {
            NSLog(@"Glue: Ignoring invalid callback with id %@", callbackIdObj);
        }
        return;
    }

    NSString *service = message[@"service"];
    if (!service) {
        NSLog(@"Glue: Incoming JSON does not have a 'service' key.");
        return;
    }

    NSString *command = message[@"command"];
    if (!command) {
        NSLog(@"Glue: Incoming JSON does not have a 'command' key.");
        return;
    }

    NSString *fullName = [NSString stringWithFormat:@"%@.%@", service, command];
    [self _invokeCommand:fullName withMessage:message];
}

- (void)_invokeCommand:(NSString *)command withMessage:(NSDictionary *)incomingMessage {
    GlueAsyncCommandBlock block = _commandsToHandlers[command];
    if (!!block) {
        [self _invokeBlock:block withMessage:incomingMessage];
    } else {
        NSLog(@"Glue: Unknown command '%@' in message %@", command, incomingMessage);
    }
}

- (void)_invokeBlock:(GlueAsyncCommandBlock)block withMessage:(NSDictionary *)incomingMessage {
    block(incomingMessage, ^(NSError *error, NSDictionary *result) {
        NSDictionary *replyTemplate = incomingMessage[@"reply"];
        NSMutableDictionary *replyMessage = [replyTemplate mutableCopy] ?: [NSMutableDictionary new];
        if (error) {
            replyMessage[@"error"] = @{@"domain": error.domain, @"code": @(error.code), @"message": error.localizedDescription};
        }
        if (result) {
            replyMessage[@"result"] = result;
        }
        if (!!replyTemplate) {
            [self postMessage:replyMessage];
        } else if (error || result) {
            NSLog(@"Ignoring reply message %@ because no reply has been requested for incoming message %@", replyMessage, incomingMessage);
        }
    });
}

@end
