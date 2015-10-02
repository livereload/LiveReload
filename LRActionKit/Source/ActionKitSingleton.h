#import <Foundation/Foundation.h>

@class LRPackageManager;
@class OptionRegistry;


// stopgap approach until we can pass a proper context everywhere

@interface ActionKitSingleton : NSObject

+ (instancetype)sharedActionKit;

@property (nonatomic) OptionRegistry *optionRegistry;
@property (nonatomic) LRPackageManager *packageManager;

typedef void (^ActionKitPostMessageCompletionBlock)(NSError *error, NSDictionary *response);
typedef void (^ActionKitPostMessageBlock)(NSDictionary *message, ActionKitPostMessageCompletionBlock completionBlock);

@property (nonatomic, copy) ActionKitPostMessageBlock postMessageBlock;

@end
