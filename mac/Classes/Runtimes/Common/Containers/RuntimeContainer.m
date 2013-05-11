
#import "RuntimeContainer.h"


NSString *const LRRuntimeContainerDidChangeNotification = @"LRRuntimeContainerDidChangeNotification";


@implementation RuntimeContainer

- (id)initWithDictionary:(NSDictionary *)data {
    self = [super init];
    if (self) {
        _memento = [data mutableCopy];
    }
    return self;
}

- (BOOL)exposedToUser {
    return YES;
}

- (NSString *)title {
    return @"Unnamed";
}

- (void)validateAndDiscover {

}

- (void)didChange {
    [[NSNotificationCenter defaultCenter] postNotificationName:LRRuntimeContainerDidChangeNotification object:self];
}

@end
