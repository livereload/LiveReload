
#import "RuntimeManager.h"
#import "RuntimeInstance.h"


NSString *const LRRuntimesDidChangeNotification = @"LRRuntimesDidChangeNotification";



@implementation RuntimeManager {
    BOOL _scheduledRuntimesDidChangeNotification;
    BOOL _dirty;
}

- (id)init {
    self = [super init];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(runtimeDidChange:) name:LRRuntimeInstanceDidChangeNotification object:nil];
    }
    return self;
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

- (void)runtimeDidChange:(NSNotification *)notification {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self saveSoon];
    });
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
    return [[RuntimeInstance alloc] initWithMemento:memento additionalInfo:nil];
}

@end
