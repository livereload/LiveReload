#import "RubyRuntimeRepository.h"
#import "RuntimeContainer.h"
#import "NSData+Base64.h"
#import "SystemRubyInstance.h"
#import "CustomRubyInstance.h"
#import "RuntimeContainer.h"
#import "RvmContainer.h"
#import "RbenvContainer.h"
#import "HomebrewContainer.h"



@implementation RubyRuntimeRepository

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
        [self addContainerClass:[RbenvContainer class]];
        [self addContainerClass:[HomebrewContainer class]];

        [self addInstance:[[SystemRubyInstance alloc] initWithIdentifier:@"system" executableURL:[NSURL fileURLWithPath:@"/usr/bin/ruby"]]];
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
