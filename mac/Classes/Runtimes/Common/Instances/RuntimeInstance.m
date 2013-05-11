
#import "RuntimeInstance.h"


NSString *const LRRuntimeInstanceDidChangeNotification = @"LRRuntimeInstanceDidChangeNotification";


@implementation NRuntimeInstance {
    NSMutableDictionary *_memento;
}

- (id)initWithDictionary:(NSDictionary *)data {
    self = [super init];
    if (self) {
        _memento = [data mutableCopy];
        _identifier = [[data objectForKey:@"identifier"] copy];
        _executablePath = [[data objectForKey:@"executablePath"] copy];
        _basicTitle = [[data objectForKey:@"basicTitle"] copy];
    }
    return self;
}

- (NSDictionary *)memento {
    return _memento;
}

- (NSURL *)executableURL {
    return [NSURL fileURLWithPath:self.executablePath];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"Ruby at %@", self.executablePath];
}

- (NSString *)title {
    NSString *title;
    if ([self.version length] > 0)
        title = [NSString stringWithFormat:@"%@ %@", self.basicTitle, self.version];
    else
        title = self.basicTitle;

    //    if (self.executablePath.length > 0)
    //        title = [NSString stringWithFormat:@"%@ at %@", title, self.executablePath];

    NSString *qualifier = self.statusQualifier;
    if (qualifier.length > 0)
        title = [NSString stringWithFormat:@"%@ (%@)", title, qualifier];

    return title;
}

- (NSString *)statusQualifier {
    if (self.validationPerformed)
        if (self.valid)
            return @"";
        else
            return @"broken";
        else
            if (self.validationInProgress)
                return @"validating";
            else
                return @"to be validated";
}

- (void)validate {
    if (self.validationPerformed || self.validationInProgress)
        return;

    NSLog(@"Validation of %@...", self);

    self.validationInProgress = YES;
    [self doValidate];
}

- (void)validationSucceededWithData:(NSDictionary *)data {
    NSLog(@"Validation of %@ succeeded: %@", self, data);
    self.version = [data objectForKey:@"version"];
    self.valid = YES;
    self.validationPerformed = YES;
    self.validationInProgress = NO;
    [self didChange];
}

- (void)validationFailedWithError:(NSError *)error {
    NSLog(@"Validation of %@ failed: %@", self, [error localizedDescription]);
    self.valid = NO;
    self.validationPerformed = YES;
    self.validationInProgress = NO;
    [self didChange];
}

- (void)doValidate {
    NSAssert(NO, @"doValidate must be implemented");
}

- (void)didChange {
    [[NSNotificationCenter defaultCenter] postNotificationName:LRRuntimeInstanceDidChangeNotification object:self];
}

@end
