
#import "Editor.h"


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

- (NSString *)displayName {
    MustOverride();
}

- (BOOL)jumpToFile:(NSString *)file line:(NSInteger)line {
    MustOverride();
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

@end
