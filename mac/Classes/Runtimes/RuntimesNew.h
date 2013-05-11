
#import <Foundation/Foundation.h>

#import "RuntimeInstance.h"


extern NSString *const LRRuntimesDidChangeNotification;

void PostRuntimesDidChangeNotification();


@interface RuntimeManager : NSObject

- (void)addContainerClass:(Class)containerClass;

- (void)load;

- (RuntimeInstance *)instanceIdentifiedBy:(NSString *)identifier;

- (void)runtimesDidChange;

- (RuntimeInstance *)newInstanceWithDictionary:(NSDictionary *)memento;

- (RuntimeInstance *)missingInstanceWithData:(NSDictionary *)data; // override point

@end






//@interface RuntimeVariant : NSObject
//
//@end
