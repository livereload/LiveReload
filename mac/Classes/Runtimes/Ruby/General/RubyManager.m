#import "RubyManager.h"
#import "RuntimeContainer.h"
#import "NSData+Base64.h"
#import "RubyInstance.h"
#import "RvmContainer.h"
#import "MissingRuntimeInstance.h"



@implementation RubyManager {
    NSMutableDictionary *_instancesByIdentifier;
    NSMutableArray *_instances;
    NSMutableArray *_containers;

    NSMutableArray *_customInstances;
    NSMutableArray *_customContainers;
}

RubyManager *sharedRubyManager;
+ (RubyManager *)sharedRubyManager {
    return sharedRubyManager;
}

- (NSArray *)instances {
    return _instances;
}

- (NSArray *)containers {
    return _containers;
}

- (void)addInstance:(RuntimeInstance *)instance {
    [_instances addObject:instance];
    [_instancesByIdentifier setObject:instance forKey:instance.identifier];
    [instance validate];
    [self runtimesDidChange];
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

- (RuntimeInstance *)addCustomRubyAtURL:(NSURL *)url {
    NSError *error;
    NSString *bookmark = [[url bookmarkDataWithOptions:NSURLBookmarkCreationWithSecurityScope|NSURLBookmarkCreationSecurityScopeAllowOnlyReadAccess includingResourceValuesForKeys:nil relativeToURL:nil error:&error] base64EncodedString];
    if (!bookmark) {
        NSLog(@"Failed to create a security-scoped bookmark for Ruby at %@", url);
        bookmark = @"";
    }

    RubyInstance *instance = [[RubyInstance alloc] initWithDictionary:@{
                              @"identifier": [url path],
                              @"executablePath": [[url path] stringByAppendingPathComponent:@"bin/ruby"],
                              @"basicTitle": [NSString stringWithFormat:@"Ruby at %@", [url path]],
                              @"bookmark": bookmark,
                              }];
    [self addInstance:instance];
    [_customInstances addObject:instance];
    return instance;
}

- (id)init {
    self = [super init];
    if (self) {
        _instancesByIdentifier = [[NSMutableDictionary alloc] init];
        _instances = [[NSMutableArray alloc] init];
        _customInstances = [[NSMutableArray alloc] init];
        _containers = [[NSMutableArray alloc] init];
        _customContainers = [[NSMutableArray alloc] init];

        [self addInstance:[[RubyInstance alloc] initWithDictionary:@{
                           @"identifier": @"system",
                           @"executablePath": @"/usr/bin/ruby",
                           @"basicTitle": @"System Ruby",
                           }]];

        sharedRubyManager = [self retain];
        [self load];
    }
    return self;
}

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
        result = [[MissingRuntimeInstance alloc] initWithDictionary:@{@"identifier": identifier}];
    return result;
}

- (void)runtimesDidChange {
    [super runtimesDidChange];
}

- (NSDictionary *)memento {
    return @{@"customRubies": [_customInstances valueForKey:@"memento"], @"containers": [_customContainers valueForKey:@"memento"]};
}

- (RuntimeInstance *)newInstanceWithDictionary:(NSDictionary *)memento {
    return [[RubyInstance alloc] initWithDictionary:memento];
}

- (RuntimeContainer *)newContainerWithMemento:(NSDictionary *)memento {
    NSString *type = memento[@"type"];
    if ([type isEqualToString:@"rvm"]) {
        return [[RvmContainer alloc] initWithMemento:memento userInfo:nil];
    } else {
        return nil;
    }
}

- (void)setMemento:(NSDictionary *)dictionary {
    for (NSDictionary *instanceMemento in dictionary[@"customRubies"]) {
        RubyInstance *instance = (RubyInstance *) [self newInstanceWithDictionary:instanceMemento];
        if (instance) {
            [instance resolveBookmark];
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

@end
