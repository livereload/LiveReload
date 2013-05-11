#import "Runtimes.h"


NSString *const LRRuntimesDidChangeNotification = @"LRRuntimesDidChangeNotification";




@protocol RuntimeInstanceOwner <NSObject>

- (void)instanceDidChange;

@end


@interface RuntimeContainerType : NSObject

@property(nonatomic, readonly) Class containerClass;
@property(nonatomic, readonly) NSString *typeCode;

@end


@implementation RuntimeContainerType

- (id)initWithContainerClass:(Class)containerClass {
    self = [super init];
    if (self) {
        _containerClass = containerClass;
        _typeCode = [[(id)containerClass typeCode] retain];
    }
    return self;
}

@end



@implementation RuntimeManager {
    NSMutableArray *_containers;

    NSMutableArray *_containerTypes;


    BOOL _scheduledRuntimesDidChangeNotification;
    BOOL _dirty;

    NSMutableArray *_instances;

    NSMutableArray *_customContainers;

    NSArray *_availableInstances;
}

- (id)init {
    self = [super init];
    if (self) {
//        _customInstances = [[NSMutableArray alloc] init];
        _customContainers = [[NSMutableArray alloc] init];

        _instances = [[NSMutableArray alloc] init];
    }
    return self;
}


#pragma mark - Available Instances

- (void)startManagingInstance:(RuntimeInstance *)instance {
    instance.manager = self;
}

- (void)stopManagingInstance:(RuntimeInstance *)instance {
    instance.manager = nil;
}

- (void)setAvailableInstances:(NSArray *)instances {
    NSMutableDictionary *oldInstancesMap = [NSMutableDictionary dictionary];
    for (RuntimeInstance *oldInstance in _availableInstances) {
        [oldInstancesMap setObject:oldInstance forKey:oldInstance.identifier];
    }

    for (RuntimeInstance *newInstance in instances) {
        RuntimeInstance *oldInstance = oldInstancesMap[newInstance.identifier];
        if (oldInstance != newInstance) {
            if (oldInstance) {
                [self stopManagingInstance:oldInstance];
            }
            [self startManagingInstance:newInstance];
        }
        [oldInstancesMap removeObjectForKey:newInstance.identifier];
    }

    for (RuntimeInstance *removedInstance in [oldInstancesMap allValues]) {
        [self stopManagingInstance:removedInstance];
    }

    _availableInstances = [instances copy];
}

- (void)updateAvailableInstances {
    NSMutableArray *instances = [NSMutableArray array];
    for (RuntimeContainer *container in _containers) {
        [instances addObjectsFromArray:container.instances];
    }
    [self setAvailableInstances:instances];
}

- (void)availableInstancesDidChange {
    [self updateAvailableInstances];
}


#pragma mark - Instance Lookup

- (RuntimeInstance *)instanceWithBookmark:(NSString *)instanceBookmark {
    NSArray *components = [instanceBookmark componentsSeparatedByString:@":"];
    NSString *containerTypeCode = components[0];

    for (RuntimeInstance *instance in _instances) {
        if ([instance.identifier isEqualToString:identifier])
            return instance;
    }
    return [self missingInstanceWithData:@{@"identifier": identifier}];
}

- (RuntimeInstance *)missingInstanceWithData:(NSDictionary *)data {
    return [[MissingRuntimeInstance alloc] initWithDictionary:data];
}



#pragma mark - Containers

- (void)addContainer:(RuntimeContainer *)container {
    container.manager = self;

    [_containers addObject:container];
    [self containersDidChange];
}

- (void)removeContainer:(RuntimeContainer *)container {
    if (container.manager != self)
        return;
    container.manager = nil;

    [_containers removeObject:container];
    [self containersDidChange];
}

- (void)containersDidChange {
    [self availableInstancesDidChange];
}


#pragma mark - Container Types

- (void)addContainerClass:(Class)containerClass {
    RuntimeContainerType *type = [[RuntimeContainerType alloc] initWithContainerClass:containerClass];
    [_containerTypes addObject:type];
}

- (RuntimeContainerType *)containerTypeWithCode:(NSString *)typeCode {
    for (RuntimeContainerType *type in _containerTypes) {
        if ([type.typeCode isEqualToString:typeCode])
            return type;
    }
    return nil;
}

- (RuntimeContainer *)newContainerWithTypeCode:(NSString *)typeCode data:(NSDictionary *)data {
    RuntimeContainerType *type = [self containerTypeWithCode:typeCode];
    if (!type)
        return nil;

    return [[type.containerClass alloc] initWithDictionary:data];
}

- (void)runtimesDidChange {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self saveSoon];

        if (_scheduledRuntimesDidChangeNotification)
            return;
        _scheduledRuntimesDidChangeNotification = YES;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 10 * NSEC_PER_MSEC), dispatch_get_main_queue(), ^{
            _scheduledRuntimesDidChangeNotification = NO;
            [[NSNotificationCenter defaultCenter] postNotificationName:LRRuntimesDidChangeNotification object:self];
        });
    });
}

- (void)runtimeDidChange:(RuntimeInstance *)instance {
    [self runtimesDidChange];
}

- (NSString *)dataFilePath {
    return [[[[NSFileManager defaultManager] URLForDirectory:NSApplicationSupportDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:NULL] path] stringByAppendingPathComponent:@"LiveReload/Data/rubies.json"];
}

- (NSDictionary *)memento {
    return @{};
}

- (void)setMemento:(NSDictionary *)dictionary {
}

- (void)load {
    NSDictionary *dictionary = [NSDictionary dictionary];

    NSData *data = [NSData dataWithContentsOfFile:[self dataFilePath] options:NSDataReadingUncached error:NULL];
    if (data) {
        id obj = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:NULL];
        if (obj) {
            dictionary = obj;
        }
    }

    [self setMemento:dictionary];
}

- (void)saveSoon {
    _dirty = YES;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 50 * NSEC_PER_MSEC), dispatch_get_main_queue(), ^{
        _dirty = NO;
        [self saveNow];
    });
}

- (void)saveNow {
    [[NSFileManager defaultManager] createDirectoryAtPath:[self.dataFilePath stringByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:NULL];
    [[NSJSONSerialization dataWithJSONObject:self.memento options:NSJSONWritingPrettyPrinted error:NULL] writeToFile:self.dataFilePath options:NSDataWritingAtomic error:NULL];
}

- (RuntimeInstance *)newInstanceWithDictionary:(NSDictionary *)memento {
    return [[RuntimeInstance alloc] initWithDictionary:memento];
}

@end



@implementation RuntimeContainer


@end

//@implementation RuntimeVariant
//
//@end
