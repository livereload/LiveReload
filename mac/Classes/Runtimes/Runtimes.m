#import "Runtimes.h"


NSString *const LRRuntimeManagerErrorDomain = @"LRRuntimeManagerErrorDomain";


@implementation RuntimeManager

//- (RuntimeInstance *)instanceIdentifiedBy:(NSString *)identifier;

@end

@implementation RuntimeInstance

- (id)initWithDictionary:(NSDictionary *)data {
    self = [super init];
    if (self) {
        _identifier = [data objectForKey:@"identifier"];
        _executablePath = [data objectForKey:@"executablePath"];
        _basicTitle = [data objectForKey:@"basicTitle"];
    }
    return self;
}

- (NSURL *)executableURL {
    return [NSURL fileURLWithPath:self.executablePath];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"Ruby at %@", self.executablePath];
}

- (NSString *)title {
    NSString *nameAndVersion;
    if ([self.version length] > 0)
        nameAndVersion = [NSString stringWithFormat:@"%@ %@", self.basicTitle, self.version];
    else
        nameAndVersion = self.basicTitle;

    NSString *qualifier = self.statusQualifier;
    if (qualifier.length > 0)
        qualifier = [NSString stringWithFormat:@" (%@)", qualifier];

    return [NSString stringWithFormat:@"%@ at %@%@", nameAndVersion, self.executablePath, qualifier];
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
}

- (void)validationFailedWithError:(NSError *)error {
    NSLog(@"Validation of %@ failed: %@", self, [error localizedDescription]);
    self.valid = NO;
    self.validationPerformed = YES;
    self.validationInProgress = NO;
}

- (void)doValidate {
    NSAssert(NO, @"doValidate must be implemented");
}

@end

//@implementation RuntimeVariant
//
//@end
