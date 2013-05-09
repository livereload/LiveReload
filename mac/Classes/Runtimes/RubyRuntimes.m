
#import "RubyRuntimes.h"

#import "NSTask+OneLineTasksWithOutput.h"
#import "PlainUnixTask.h"
#import "TaskOutputReader.h"
#import "NSData+Base64.h"


NSString *RubyVersionAtPath(NSString *executablePath) {
    NSError *error = nil;
    NSArray *components = [[[NSTask stringByLaunchingPath:executablePath withArguments:[NSArray arrayWithObject:@"--version"] error:&error] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if (error)
        return nil;
    if ([[components objectAtIndex:0] isEqualToString:@"ruby"] && components.count > 1)
        return [components objectAtIndex:1];
    return nil;
}


@implementation RubyManager {
    NSMutableDictionary *_instancesByIdentifier;
    NSMutableArray *_instances;
}

RubyManager *sharedRubyManager;
+ (RubyManager *)sharedRubyManager {
    return sharedRubyManager;
}

- (NSArray *)instances {
    return _instances;
}

- (void)addInstance:(RuntimeInstance *)instance {
    [_instances addObject:instance];
    [_instancesByIdentifier setObject:instance forKey:instance.identifier];
    [instance validate];
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
    return instance;
}

- (id)init {
    self = [super init];
    if (self) {
        _instancesByIdentifier = [[NSMutableDictionary alloc] init];
        _instances = [[NSMutableArray alloc] init];

        [self addInstance:[[RubyInstance alloc] initWithDictionary:@{
            @"identifier": @"system",
            @"executablePath": @"/usr/bin/ruby",
            @"basicTitle": @"System Ruby",
        }]];

        sharedRubyManager = [self retain];
    }
    return self;
}

- (RuntimeInstance *)instanceIdentifiedBy:(NSString *)identifier {
    return [_instancesByIdentifier objectForKey:identifier];
}

@end


@implementation RubyInstance

- (void)doValidate {
    NSError *error;
    PlainUnixTask *task = [[PlainUnixTask alloc] initWithURL:self.executableURL error:&error];
    if (!task) {
        [self validationFailedWithError:[NSError errorWithDomain:LRRuntimeManagerErrorDomain code:LRRuntimeManagerErrorValidationFailed userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"Failed to create a task for validation"]}]];
        return;
    }

    TaskOutputReader *reader = [[TaskOutputReader alloc] initWithTask:task];
    [task executeWithArguments:@[@"--version"] completionHandler:^(NSError *error) {
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

//- (void)validate {
//    NSFileManager *fm = [NSFileManager defaultManager];
//    _valid = [fm fileExistsAtPath:[self executablePath]];
//}
//
//- (NSString *)title {
//    if (_versionName == nil) {
//        _versionName = [RubyVersionAtPath(self.executablePath) retain];
//    }
//    if (self.valid && _versionName)
//        return [NSString stringWithFormat:@"System Ruby %@", _versionName];
//    else
//        return @"System Ruby";
//}
