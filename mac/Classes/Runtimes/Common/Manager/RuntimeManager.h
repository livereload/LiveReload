
#import <Foundation/Foundation.h>


extern NSString *const LRRuntimesDidChangeNotification;


@class RuntimeInstance, RuntimeContainer;


@interface RuntimeManager : NSObject

@property(nonatomic, readonly, strong) NSArray *instances;
@property(nonatomic, readonly, strong) NSArray *containers;

- (RuntimeInstance *)instanceIdentifiedBy:(NSString *)identifier;

- (void)addInstance:(RuntimeInstance *)instance;
- (void)addCustomInstance:(RuntimeInstance *)instance;

- (void)addContainerClass:(Class)containerClass;
- (void)addContainer:(RuntimeContainer *)container;
- (void)addCustomContainer:(RuntimeContainer *)container;

- (void)load;
- (void)runtimesDidChange;

// override points;
- (NSString *)dataFileName;
- (RuntimeInstance *)newInstanceWithMemento:(NSDictionary *)memento;
- (RuntimeContainer *)newContainerWithMemento:(NSDictionary *)memento;

@end
