
#import <Foundation/Foundation.h>


extern NSString *const LRRuntimesDidChangeNotification;


@class RuntimeInstance, RuntimeContainer;
@protocol RuntimeObject;


@interface RuntimeRepository : NSObject

@property(nonatomic, readonly, strong) NSArray *instances;
@property(nonatomic, readonly, strong) NSArray *containers;

- (RuntimeInstance *)instanceIdentifiedBy:(NSString *)identifier;

- (void)addInstance:(RuntimeInstance *)instance;
- (void)addCustomInstance:(RuntimeInstance *)instance;
- (void)removeInstance:(RuntimeInstance *)instance;

- (void)addContainerClass:(Class)containerClass;
- (void)addContainer:(RuntimeContainer *)container;
- (void)addCustomContainer:(RuntimeContainer *)container;
- (void)removeContainer:(RuntimeContainer *)container;

- (void)addCustomRuntimeObject:(id<RuntimeObject>)object;
- (BOOL)canRemoveRuntimeObject:(id<RuntimeObject>)object;
- (void)removeRuntimeObject:(id<RuntimeObject>)object;

- (void)load;
- (void)runtimesDidChange;

// override points;
- (NSString *)dataFileName;
- (RuntimeInstance *)newInstanceWithMemento:(NSDictionary *)memento;
- (RuntimeContainer *)newContainerWithMemento:(NSDictionary *)memento;

@end
