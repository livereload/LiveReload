
#import "MissingRuntimeInstance.h"

@implementation NMissingRuntimeInstance

- (id)initWithDictionary:(NSDictionary *)data {
    self = [super initWithDictionary:data];
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
