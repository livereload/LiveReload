
#import "RuntimeRepository.h"
#import "RuntimeInstance.h"
#import "RuntimeContainer.h"
#import "MissingRuntimeInstance.h"


NSString *const LRRuntimesDidChangeNotification = @"LRRuntimesDidChangeNotification";



@interface RuntimeRepository ()

@end



@implementation RuntimeRepository {
    NSMutableDictionary *_instancesByIdentifier;
    NSMutableArray *_instances;
    NSMutableArray *_containers;

    NSMutableArray *_customInstances;
    NSMutableArray *_customContainers;

    NSMutableDictionary *_containerTypes;

    BOOL _scheduledRuntimesDidChangeNotification;
    BOOL _dirty;
}

- (id)init {
    self = [super init];
    if (self) {
        _containerTypes = [[NSMutableDictionary alloc] init];

        _instancesByIdentifier = [[NSMutableDictionary alloc] init];
        _instances = [[NSMutableArray alloc] init];
        _customInstances = [[NSMutableArray alloc] init];

        _containers = [[NSMutableArray alloc] init];
        _customContainers = [[NSMutableArray alloc] init];

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(runtimeDidChange:) name:LRRuntimeInstanceDidChangeNotification object:nil];
    }
    return self;
}



#pragma mark - Instances

- (NSArray *)instances {
    return _instances;
}

- (void)addInstance:(RuntimeInstance *)instance {
    [_instances addObject:instance];
    [_instancesByIdentifier setObject:instance forKey:instance.identifier];
    [instance validate];
    [self runtimesDidChange];
}

- (void)addCustomInstance:(RuntimeInstance *)instance {
    [_customInstances addObject:instance];
    [self addInstance:instance];
}



#pragma mark - Containers

- (NSArray *)containers {
    return _containers;
}

- (void)addContainerClass:(Class)containerClass {
    NSString *typeIdentifier = [containerClass containerTypeIdentifier];
    _containerTypes[typeIdentifier] = containerClass;
}

- (void)addContainer:(RuntimeContainer *)container {
    [_containers addObject:container];
    [container validate];
    [self runtimesDidChange];
}

- (void)addCustomContainer:(RuntimeContainer *)container {
    [_customContainers addObject:container];
    [self addContainer:container];
}



#pragma mark - Lookup

- (RuntimeInstance *)instanceIdentifiedBy:(NSString *)identifier {
    RuntimeInstance *result = [_instancesByIdentifier objectForKey:identifier];
    if (!result) {
        for (RuntimeContainer *container in _containers) {
            result = [container instanceIdentifiedBy:identifier];
            if (result)
                break;
        }
    }
    if (!result)
        result = [[MissingRuntimeInstance alloc] initWithMemento:@{@"identifier": identifier} additionalInfo:nil];
    return result;
}



#pragma mark - Change events

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

- (void)runtimeDidChange:(NSNotification *)notification {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self saveSoon];
    });
}


#pragma mark - Instance creation

- (RuntimeInstance *)newInstanceWithMemento:(NSDictionary *)memento {
    return nil;
}

- (RuntimeContainer *)newContainerWithMemento:(NSDictionary *)memento {
    NSString *type = memento[@"type"];
    if ([type length] > 0) {
        Class containerClass = _containerTypes[type];
        if (containerClass) {
            return [[containerClass alloc] initWithMemento:memento additionalInfo:nil];
        }
    }
    return nil;
}



#pragma mark - Memento

- (NSDictionary *)memento {
    return @{@"instances": [_customInstances valueForKey:@"memento"], @"containers": [_customContainers valueForKey:@"memento"]};
}

- (void)setMemento:(NSDictionary *)dictionary {
    for (NSDictionary *instanceMemento in dictionary[@"instances"]) {
        RuntimeInstance *instance = [self newInstanceWithMemento:instanceMemento];
        if (instance) {
            [_customInstances addObject:instance];
            [self addInstance:instance];
        }
    }
    for (NSDictionary *containerMemento in dictionary[@"containers"]) {
        RuntimeContainer *container = [self newContainerWithMemento:containerMemento];
        if (container) {
            [_customContainers addObject:container];
            [self addContainer:container];
        }
    }
    [self runtimesDidChange];
}



#pragma mark - Persistence

- (NSString *)dataFileName {
    abort();
}

- (NSString *)dataFilePath {
    return [[[[[NSFileManager defaultManager] URLForDirectory:NSApplicationSupportDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:NULL] path] stringByAppendingPathComponent:@"LiveReload/Data"] stringByAppendingPathComponent:[self dataFileName]];
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


@end
