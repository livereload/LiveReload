
#import "MissingRuntimeInstance.h"

@implementation MissingRuntimeInstance

- (id)initWithMemento:(NSDictionary *)memento additionalInfo:(NSDictionary *)additionalInfo {
    self = [super initWithMemento:memento additionalInfo:additionalInfo];
    if (self) {
        self.valid = NO;
        self.validationPerformed = YES;
    }
    return self;
}

- (NSString *)statusQualifier {
    return @"missing";
}

- (NSString *)basicTitle {
    return self.identifier;
}

@end
