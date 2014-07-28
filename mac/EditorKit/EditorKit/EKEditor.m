
#import "EKEditor.h"
#import "EKJumpRequest.h"


static NSString *EditorStateStrings[] = {
    @"EditorStateNotFound",
    @"EditorStateBroken",
    @"EditorStateFound",
    @"EditorStateRunning",
};


@interface EKEditor ()

@property(nonatomic, assign) EKEditorState state;
@property(nonatomic, assign, getter=isStateStale) BOOL stateStale;

@end


@implementation EKEditor

@synthesize identifier = _identifier;
@synthesize displayName = _displayName;
@synthesize cocoaBundleId = _cocoaBundleId;

@synthesize state = _state;
@synthesize stateStale = _stateStale;

@synthesize mruPosition = _mruPosition;
@synthesize defaultPriority = _defaultPriority;

- (id)init {
    self = [super init];
    if (self) {
        _mruPosition = NSNotFound;

        [self updateStateSoon];
    }
    return self;
}

- (void)jumpWithRequest:(EKJumpRequest *)request completionHandler:(void(^)(NSError *error))completionHandler {
    abort(); // must override
}

- (BOOL)jumpToFile:(NSString *)file line:(NSInteger)line {
    [self jumpWithRequest:[[EKJumpRequest alloc] initWithFileURL:[NSURL fileURLWithPath:file] line:(int)(line > 0 ? line : EKJumpRequestValueUnknown) column:EKJumpRequestValueUnknown] completionHandler:^(NSError *error) {
        if (error) 
            NSLog(@"Failed to jump to the error position: %@", error.localizedDescription);
    }];
    return YES;
}

- (BOOL)isRunning {
    return self.state == EKEditorStateRunning;
}

- (void)setAttributesDictionary:(NSDictionary *)attributes {
    self.identifier = attributes[@"id"];
    self.displayName = attributes[@"name"] ?: self.displayName;

    [self updateStateSoon];
}

- (void)updateStateSoon {
    if (self.stateStale)
        return;
    self.stateStale = YES;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_MSEC), dispatch_get_main_queue(), ^{
        [self doUpdateStateInBackground];
    });
}

- (void)updateState:(EKEditorState)state error:(NSError *)error {
    NSLog(@"Editor '%@' state is %@, error = %@", self.displayName, EditorStateStrings[state], [error localizedDescription]);
    self.state = state;
    self.stateStale = NO;
}

- (void)doUpdateStateInBackground {
    abort(); // must override
}

- (NSInteger)effectivePriority {
    NSInteger base = 0;
    if (self.state == EKEditorStateRunning)
        base = 10000;
    else if (self.state != EKEditorStateFound)
        base = -10000;
    
    if (_mruPosition != NSNotFound)
        return base + 1000 - _mruPosition;
    else
        return base + _defaultPriority;
}

@end

@implementation InternalEditor

@end
