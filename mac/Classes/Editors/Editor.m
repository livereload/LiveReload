
#import "Editor.h"
#import "Errors.h"


static NSString *EditorStateStrings[] = {
    @"EditorStateNotFound",
    @"EditorStateBroken",
    @"EditorStateFound",
    @"EditorStateRunning",
};


@interface Editor ()

@property(nonatomic, assign) EditorState state;
@property(nonatomic, assign, getter=isStateStale) BOOL stateStale;

@end

@implementation Editor

@synthesize state = _state;
@synthesize stateStale = _stateStale;
@synthesize mruPosition = _mruPosition;
@synthesize defaultPriority = _defaultPriority;

- (id)init
{
    self = [super init];
    if (self) {
        _mruPosition = NSNotFound;
    }
    return self;
}

- (NSString *)identifier {
    MustOverride();
}

- (NSString *)displayName {
    MustOverride();
}

- (BOOL)jumpToFile:(NSString *)file line:(NSInteger)line {
    MustOverride();
}

- (BOOL)isRunning {
    return self.state == EditorStateRunning;
}

- (void)updateStateSoon {
    if (self.stateStale)
        return;
    self.stateStale = YES;
    [self doUpdateStateInBackground];
}

- (void)updateState:(EditorState)state error:(NSError *)error {
    NSLog(@"Editor '%@' state is %@, error = %@", self.displayName, EditorStateStrings[state], [error localizedDescription]);
    self.state = state;
    self.stateStale = NO;
}

- (void)doUpdateStateInBackground {
    MustOverride();
}

- (NSInteger)effectivePriority {
    NSInteger base = 0;
    if (self.state == EditorStateRunning)
        base = 10000;
    else if (self.state != EditorStateFound)
        base = -10000;
    
    if (_mruPosition != NSNotFound)
        return base + 1000 - _mruPosition;
    else
        return base + _defaultPriority;
}

@end
