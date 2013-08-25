
#import "ActionType.h"
#import "Action.h"

@implementation ActionType

- (id)initWithClass:(Class)klass kind:(ActionKind)kind {
    self = [super init];
    if (self) {
        _identifier = [[klass typeIdentifier] copy];
        _klass = klass;
        _kind = kind;
    }
    return self;
}

@end
