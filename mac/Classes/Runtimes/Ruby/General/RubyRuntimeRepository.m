#import "RubyRuntimeRepository.h"
#import "RuntimeContainer.h"
#import "NSData+Base64.h"
#import "RubyInstance.h"
#import "RuntimeContainer.h"
#import "RvmContainer.h"
#import "CustomRubyInstance.h"



@implementation RubyRuntimeRepository

RubyRuntimeRepository *sharedRubyManager;
+ (RubyRuntimeRepository *)sharedRubyManager {
    return sharedRubyManager;
}

- (RuntimeInstance *)addCustomRubyAtURL:(NSURL *)url {
    NSError *error;
    NSString *bookmark = [[url bookmarkDataWithOptions:NSURLBookmarkCreationWithSecurityScope|NSURLBookmarkCreationSecurityScopeAllowOnlyReadAccess includingResourceValuesForKeys:nil relativeToURL:nil error:&error] base64EncodedString];
    if (!bookmark) {
        NSLog(@"Failed to create a security-scoped bookmark for Ruby at %@", url);
        bookmark = @"";
    }

    RubyInstance *instance = [[RubyInstance alloc] initWithMemento:@{
                              @"identifier": [url path],
                              @"executablePath": [[url path] stringByAppendingPathComponent:@"bin/ruby"],
                              @"basicTitle": [NSString stringWithFormat:@"Ruby at %@", [url path]],
                              @"bookmark": bookmark,
                              } additionalInfo:nil];
    [self addCustomInstance:instance];
    return instance;
}

- (id)init {
    self = [super init];
    if (self) {
        [self addContainerClass:[RvmContainer class]];

        [self addInstance:[[RubyInstance alloc] initWithMemento:@{
                           @"identifier": @"system",
                           @"executablePath": @"/usr/bin/ruby",
                           @"basicTitle": @"System Ruby",
                           } additionalInfo:nil]];

        sharedRubyManager = [self retain];
    }
    return self;
}


- (RuntimeInstance *)newInstanceWithMemento:(NSDictionary *)memento {
    return [[CustomRubyInstance alloc] initWithMemento:memento additionalInfo:nil];
}

- (NSString *)dataFileName {
    return @"rubies.json";
}


@end
