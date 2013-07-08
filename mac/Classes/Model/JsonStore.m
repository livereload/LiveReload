
#import "JsonStore.h"

@interface JsonStore ()

@property(nonatomic, strong) id<JsonConvertible> owner;

@end

@implementation JsonStore

- (id)initWithPath:(NSString *)path owner:(id<JsonConvertible>)owner {
    self = [super init];
    if (self) {
        _owner = [owner retain];
    }
    return self;
}

@end
