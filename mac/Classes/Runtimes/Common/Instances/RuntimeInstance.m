
#import "RuntimeInstance.h"


NSString *const LRRuntimeInstanceDidChangeNotification = @"LRRuntimeInstanceDidChangeNotification";


@implementation RuntimeInstance {
    NSMutableDictionary *_memento;
}

- (id)initWithMemento:(NSDictionary *)memento additionalInfo:(NSDictionary *)additionalInfo {
    self = [super init];
    if (self) {
        _memento = [memento mutableCopy] ?: [[NSMutableDictionary alloc] init];
        self.identifier = memento[@"identifier"];
    }
    return self;
}

- (NSDictionary *)memento {
    return _memento;
}

- (NSString *)executablePath {
    return [self.executableURL path];
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

    NSString *detail = self.titleDetail;
    if (detail.length > 0)
        title = [NSString stringWithFormat:@"%@ %@", title, detail];

    NSString *qualifier = self.statusQualifier;
    if (qualifier.length > 0)
        title = [NSString stringWithFormat:@"%@ (%@)", title, qualifier];

    return title;
}

- (NSString *)titleDetail {
    return nil;
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

- (NSURL *)url {
    return self.executableURL;
}

- (NSString *)validationResultSummary {
    if (self.valid)
        return [NSString stringWithFormat:@"v%@", self.version];
    else
        return @"invalid";
}

- (BOOL)subtreeValidationInProgress {
    return self.validationInProgress;
}

- (NSString *)subtreeValidationResultSummary {
    return self.validationResultSummary;
}

- (void)didChange {
    [[NSNotificationCenter defaultCenter] postNotificationName:LRRuntimeInstanceDidChangeNotification object:self];
}

- (BOOL)isPersistent {
    return NO;
}


#pragma mark - Presentation

- (NSURL *)executableURL {
    abort();
}

- (NSString *)imageName {
    abort();
}

- (NSString *)mainLabel {
    NSString *title;
    if ([self.version length] > 0)
        title = [NSString stringWithFormat:@"%@ %@", self.basicTitle, self.version];
    else
        title = self.basicTitle;

    NSString *qualifier = self.statusQualifier;
    if (qualifier.length > 0)
        title = [NSString stringWithFormat:@"%@ (%@)", title, qualifier];

    return title;
}

- (NSString *)detailLabel {
    abort();
}

@end
