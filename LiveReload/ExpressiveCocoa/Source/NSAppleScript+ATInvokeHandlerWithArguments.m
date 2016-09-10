
#import "NSAppleScript+ATInvokeHandlerWithArguments.h"


#ifndef kASAppleScriptSuite
#define kASAppleScriptSuite 'ascr'
#endif

#ifndef kASSubroutineEvent
#define kASSubroutineEvent 'psbr'
#endif

#ifndef keyASSubroutineName
#define keyASSubroutineName 'snam'
#endif


@implementation NSAppleScript (ATInvokeHandlerWithArguments)

- (NSAppleEventDescriptor *)executeHandlerNamed:(NSString *)handleName withArguments:(NSArray *)arguments error:(NSDictionary **)errorInfo {
    NSAppleEventDescriptor *params = [NSAppleEventDescriptor listDescriptor];
    NSInteger paramIndex = 1;
    for (id object in arguments) {
        NSAppleEventDescriptor *wrapped;
        if ([object isKindOfClass:[NSAppleEventDescriptor class]])
            wrapped = object;
        else if ([object isKindOfClass:[NSString class]])
            wrapped = [NSAppleEventDescriptor descriptorWithString:object];
        else if ([object isKindOfClass:[NSNumber class]])
            wrapped = [NSAppleEventDescriptor descriptorWithInt32:[object intValue]];
        else
            @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"Unknown argument type in %s" userInfo:nil];
        [params insertDescriptor:wrapped atIndex:paramIndex++];
    }

    ProcessSerialNumber psn = {0, kCurrentProcess};
    NSAppleEventDescriptor *target = [NSAppleEventDescriptor descriptorWithDescriptorType:typeProcessSerialNumber bytes:&psn length:sizeof(psn)];

    NSAppleEventDescriptor *handler = [NSAppleEventDescriptor descriptorWithString:@"jump"];

    NSAppleEventDescriptor *event = [NSAppleEventDescriptor appleEventWithEventClass:kASAppleScriptSuite eventID:kASSubroutineEvent targetDescriptor:target returnID:kAutoGenerateReturnID transactionID:kAnyTransactionID];
    [event setParamDescriptor:handler forKeyword:keyASSubroutineName];
    [event setParamDescriptor:params forKeyword:keyDirectObject];

    return [self executeAppleEvent:event error:errorInfo];
}

@end
