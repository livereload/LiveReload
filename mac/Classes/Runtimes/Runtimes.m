#import "Runtimes.h"


NSString *const LRRuntimeManagerErrorDomain = @"LRRuntimeManagerErrorDomain";
NSString *const LRRuntimesDidChangeNotification = @"LRRuntimesDidChangeNotification";



@implementation RuntimeManager {
    BOOL _scheduledRuntimesDidChangeNotification;
    BOOL _dirty;
}

- (RuntimeInstance *)instanceIdentifiedBy:(NSString *)identifier {
    abort();
}

- (void)runtimesDidChange {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self saveSoon];

        if (_scheduledRuntimesDidChangeNotification)
            return;
        _scheduledRuntimesDidChangeNotification = YES;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 10 * NSEC_PER_MSEC), dispatch_get_main_queue(), ^{
            _scheduledRuntimesDidChangeNotification = NO;
            [[NSNotificationCenter defaultCenter] postNotificationName:LRRuntimesDidChangeNotification object:self];
        });
    });
}

- (void)runtimeDidChange:(RuntimeInstance *)instance {
    [self runtimesDidChange];
}

- (NSString *)dataFilePath {
    return [[[[NSFileManager defaultManager] URLForDirectory:NSApplicationSupportDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:NULL] path] stringByAppendingPathComponent:@"LiveReload/Data/rubies.json"];
}

- (NSDictionary *)memento {
    return @{};
}

- (void)setMemento:(NSDictionary *)dictionary {
}

- (void)load {
    NSDictionary *dictionary = [NSDictionary dictionary];

    NSData *data = [NSData dataWithContentsOfFile:[self dataFilePath] options:NSDataReadingUncached error:NULL];
    if (data) {
        id obj = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:NULL];
        if (obj) {
            dictionary = obj;
        }
    }

    [self setMemento:dictionary];
}

- (void)saveSoon {
    _dirty = YES;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 50 * NSEC_PER_MSEC), dispatch_get_main_queue(), ^{
        _dirty = NO;
        [self saveNow];
    });
}

- (void)saveNow {
    [[NSFileManager defaultManager] createDirectoryAtPath:[self.dataFilePath stringByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:NULL];
    [[NSJSONSerialization dataWithJSONObject:self.memento options:NSJSONWritingPrettyPrinted error:NULL] writeToFile:self.dataFilePath options:NSDataWritingAtomic error:NULL];
}

- (RuntimeInstance *)newInstanceWithDictionary:(NSDictionary *)memento {
    return [[RuntimeInstance alloc] initWithDictionary:memento];
}

@end

@implementation RuntimeInstance {
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
    [self.manager runtimeDidChange:self];
}

- (void)validationFailedWithError:(NSError *)error {
    NSLog(@"Validation of %@ failed: %@", self, [error localizedDescription]);
    self.valid = NO;
    self.validationPerformed = YES;
    self.validationInProgress = NO;
    [self.manager runtimeDidChange:self];
}

- (void)doValidate {
    NSAssert(NO, @"doValidate must be implemented");
}

@end


@implementation MissingRuntimeInstance

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

@end

//@implementation RuntimeVariant
//
//@end
