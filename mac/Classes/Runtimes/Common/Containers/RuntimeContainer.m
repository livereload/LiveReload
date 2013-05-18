
#import "RuntimeContainer.h"
#import "RuntimeInstance.h"
#import "ArrayDiff.h"


NSString *const LRRuntimeContainerDidChangeNotification = @"LRRuntimeContainerDidChangeNotification";


@interface RuntimeContainer ()

@property(nonatomic, assign) BOOL validationInProgress;
@property(nonatomic, assign) BOOL validationPerformed;
@property(nonatomic, assign) BOOL valid;

@end


@implementation RuntimeContainer {
    NSMutableArray *_instances;
}

- (id)initWithMemento:(NSDictionary *)memento additionalInfo:(NSDictionary *)additionalInfo {
    self = [super init];
    if (self) {
        _memento = [(memento ?: @{}) mutableCopy];
        _memento[@"type"] = [[self class] containerTypeIdentifier];
        _instances = [[NSMutableArray alloc] init];

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(runtimeInstanceDidChange:) name:LRRuntimeInstanceDidChangeNotification object:nil];
    }
    return self;
}


#pragma mark - Validation methods

- (void)validate {
    if (self.validationPerformed || self.validationInProgress)
        return;

    NSLog(@"Validation of %@...", self);

    self.validationInProgress = YES;
    [self doValidate];
}

- (BOOL)instanceValidationInProgress {
    for (RuntimeInstance *instance in _instances) {
        if (instance.validationInProgress)
            return YES;
    }
    return NO;
}

- (BOOL)subtreeValidationInProgress {
    return self.validationInProgress || self.instanceValidationInProgress;
}

- (NSString *)subtreeValidationResultSummary {
    NSUInteger limit = 3;
    NSArray *summaries = [self.instances valueForKey:@"validationResultSummary"];
    if (summaries.count <= limit) {
        return [summaries componentsJoinedByString:@", "];
    } else {
        NSUInteger len = limit - 1;
        return [[[summaries subarrayWithRange:NSMakeRange(0, len)] componentsJoinedByString:@", "] stringByAppendingFormat:@" and %d more", (int)(summaries.count - len)];
    }
}


#pragma mark - Change notification methods

- (void)didChange {
    [[NSNotificationCenter defaultCenter] postNotificationName:LRRuntimeContainerDidChangeNotification object:self];
}

- (void)runtimeInstanceDidChange:(NSNotification *)notification {
    [self didChange];  // e.g. instanceValidationInProgress might have changed
}


#pragma mark - Other RuntimeObject methods

- (NSURL *)url {
    return nil;
}


#pragma mark - Other properties

- (BOOL)exposedToUser {
    return YES;
}

- (NSString *)title {
    return @"Unnamed";
}

- (RuntimeInstance *)instanceIdentifiedBy:(NSString *)identifier {
    for (RuntimeInstance *instance in _instances) {
        if ([instance.identifier isEqualToString:identifier])
            return instance;
    }
    return nil;
}


#pragma mark - Methods for subclasses

- (void)setValid {
    NSLog(@"Validation of %@ succeeded", self);
    self.valid = YES;
    self.validationPerformed = YES;
    self.validationInProgress = NO;
    [self didChange];
}

- (void)setInvalidWithError:(NSError *)error {
    NSLog(@"Validation of %@ failed: %@", self, [error localizedDescription]);
    self.valid = NO;
    self.validationPerformed = YES;
    self.validationInProgress = NO;
    [self didChange];
}

- (void)updateInstancesWithData:(NSArray *)instancesData {
    ArrayDiffWithKeyPath(_instances, instancesData, @"identifier", ^(id newObject) {
        RuntimeInstance *instance = [self newRuntimeInstanceWithData:newObject];
        [_instances addObject:instance];
        [instance validate];
    }, ^(id oldObject) {
        [_instances removeObject:oldObject];
    }, ^(id oldObject, id newObject) {
        //
    });
    [self didChange];
}


#pragma mark - Abstract methods

+ (NSString *)containerTypeIdentifier {
    abort();
}

- (void)doValidate {
    abort();
}

- (RuntimeInstance *)newRuntimeInstanceWithData:(NSDictionary *)data {
    abort();
}

@end
