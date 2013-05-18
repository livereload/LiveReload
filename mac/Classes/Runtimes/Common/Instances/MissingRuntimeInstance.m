
#import "MissingRuntimeInstance.h"

@implementation MissingRuntimeInstance

- (id)initWithMemento:(NSDictionary *)memento additionalInfo:(NSDictionary *)additionalInfo {
    self = [super initWithMemento:memento additionalInfo:additionalInfo];
    if (self) {
        self.valid = NO;
        self.validationPerformed = YES;
        self.basicTitle = self.basicTitle ?: self.identifier;
    }
    return self;
}

- (NSString *)statusQualifier {
    return @"missing";
}

@end
