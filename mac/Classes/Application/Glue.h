
#import <Foundation/Foundation.h>


typedef void (^GlueSyncCommandBlock)(NSDictionary *message, NSError **error);

typedef void (^GlueReplyBlock)(NSError *error, NSDictionary *result);
typedef void (^GlueAsyncCommandBlock)(NSDictionary *message, GlueReplyBlock reply);

typedef void (^GlueReplyHandlerBlock)(NSError *error, id result);


@interface Glue : NSObject

+ (Glue *)glue;

- (void)postMessage:(NSDictionary *)message;
- (void)postMessage:(NSDictionary *)message withReplyHandler:(GlueReplyHandlerBlock)block;

- (void)registerCommand:(NSString *)command asyncHandler:(GlueAsyncCommandBlock)block;
- (void)registerCommand:(NSString *)command syncHandler:(GlueSyncCommandBlock)block;
- (void)registerCommand:(NSString *)command target:(id)object action:(SEL)action;

- (void)handleJsonString:(NSString *)line;
- (void)handleMessage:(NSDictionary *)message;

@end
