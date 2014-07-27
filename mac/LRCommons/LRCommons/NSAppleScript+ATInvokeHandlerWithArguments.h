
#import <Foundation/Foundation.h>

@interface NSAppleScript (ATInvokeHandlerWithArguments)

- (NSAppleEventDescriptor *)executeHandlerNamed:(NSString *)handleName withArguments:(NSArray *)arguments error:(NSDictionary **)errorInfo;

@end
