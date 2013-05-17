
#import <Foundation/Foundation.h>


extern NSString *const LRRuntimesDidChangeNotification;


@class RuntimeInstance;


@interface RuntimeManager : NSObject

- (void)load;

- (RuntimeInstance *)instanceIdentifiedBy:(NSString *)identifier;

- (void)runtimesDidChange;

- (RuntimeInstance *)newInstanceWithDictionary:(NSDictionary *)memento;

@end
