
#import "RubyRuntimes.h"

#import "NSTask+OneLineTasksWithOutput.h"
#import "PlainUnixTask.h"
#import "TaskOutputReader.h"
#import "NSData+Base64.h"
#import "ATFunctionalStyle.h"
#import "ATSandboxing.h"


NSString *GetDefaultRvmPath() {
    return [ATRealHomeDirectory() stringByAppendingPathComponent:@".rvm"];
}



@implementation OldRubyManager {
    NSMutableDictionary *_instancesByIdentifier;
    NSMutableArray *_instances;
    NSMutableArray *_containers;

    NSMutableArray *_customInstances;
    NSMutableArray *_customContainers;
}

OldRubyManager *sharedRubyManager;
+ (OldRubyManager *)sharedRubyManager {
    return sharedRubyManager;
}

- (NSArray *)instances {
    return _instances;
}

- (void)addInstance:(RuntimeInstance *)instance {
    [_instances addObject:instance];
    [_instancesByIdentifier setObject:instance forKey:instance.identifier];
    instance.manager = self;
    [instance validate];
    [self runtimesDidChange];
}

- (void)addContainer:(RuntimeContainer *)container {
    [_containers addObject:container];
    [container validateAndDiscover];
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

    OldRubyInstance *instance = [[OldRubyInstance alloc] initWithDictionary:@{
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

        [self addInstance:[[OldRubyInstance alloc] initWithDictionary:@{
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
    if (!result)
        result = [[MissingRuntimeInstance alloc] initWithDictionary:@{@"identifier": identifier}];
    return result;
}

- (void)runtimesDidChange {
    [super runtimesDidChange];
}

- (NSDictionary *)memento {
    return @{@"customRubies": [_customInstances valueForKey:@"memento"]};
}

- (RuntimeInstance *)newInstanceWithDictionary:(NSDictionary *)memento {
    return [[OldRubyInstance alloc] initWithDictionary:memento];
}

- (void)setMemento:(NSDictionary *)dictionary {
    for (NSDictionary *instanceMemento in dictionary[@"customRubies"]) {
        OldRubyInstance *instance = (OldRubyInstance *) [self newInstanceWithDictionary:instanceMemento];
        if (instance) {
            [instance resolveBookmark];
            [_customInstances addObject:instance];
            [self addInstance:instance];
        }
    }
    [self runtimesDidChange];
}

@end


@implementation OldRubyInstance

- (void)resolveBookmark {
    NSString *bookmarkString = self.memento[@"bookmark"];
    if (bookmarkString) {
        NSData *bookmark = [NSData dataFromBase64String:bookmarkString];

        BOOL stale = NO;
        NSError *error;
        NSURL *url = [NSURL URLByResolvingBookmarkData:bookmark options:NSURLBookmarkResolutionWithSecurityScope relativeToURL:nil bookmarkDataIsStale:&stale error:&error];
        if (url) {
            self.executablePath = [[url path] stringByAppendingPathComponent:@"bin/ruby"];
            self.memento[@"executablePath"] = self.executablePath;

            if (stale) {
                bookmarkString = [[url bookmarkDataWithOptions:NSURLBookmarkCreationWithSecurityScope|NSURLBookmarkCreationSecurityScopeAllowOnlyReadAccess includingResourceValuesForKeys:nil relativeToURL:nil error:&error] base64EncodedString];
                if (bookmarkString) {
                    self.memento[@"bookmark"] = bookmarkString;
                }
            }

            [url startAccessingSecurityScopedResource];
        }
    }
}

- (void)doValidate {
    NSError *error;
    PlainUnixTask *task = [[PlainUnixTask alloc] initWithURL:self.executableURL error:&error];
    if (!task) {
        [self validationFailedWithError:[NSError errorWithDomain:LRRuntimeManagerErrorDomain code:LRRuntimeManagerErrorValidationFailed userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"Failed to create a task for validation"]}]];
        return;
    }

    TaskOutputReader *reader = [[TaskOutputReader alloc] initWithTask:task];
    [task executeWithArguments:@[@"--version"] completionHandler:^(NSError *error) {
//        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2000 * NSEC_PER_MSEC), dispatch_get_main_queue(), ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            NSArray *components = [[reader.standardOutputText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            NSString *combinedOutput = reader.combinedOutputText;
            // reader can be released at this point

            if (error) {
                [self validationFailedWithError:error];
                return;
            }
            if ([[components objectAtIndex:0] isEqualToString:@"ruby"] && components.count > 1) {
                NSString *version = [components objectAtIndex:1];
                [self validationSucceededWithData:@{@"version": version}];
            } else {
                [self validationFailedWithError:[NSError errorWithDomain:LRRuntimeManagerErrorDomain code:LRRuntimeManagerErrorValidationFailed userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"Failed to parse output of --version: '%@'", combinedOutput]}]];
            }
        });
    }];
}

@end


@implementation RvmContainer

@end
