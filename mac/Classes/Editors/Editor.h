
#import <Foundation/Foundation.h>

typedef enum {
    EditorStateNotFound,
    EditorStateBroken,
    EditorStateFound,
    EditorStateRunning,
} EditorState;


@interface Editor : NSObject

@property(nonatomic, readonly, copy) NSString *identifier;
@property(nonatomic, readonly, copy) NSString *displayName;
@property(nonatomic, readonly, assign) EditorState state;
@property(nonatomic, readonly, assign, getter=isStateStale) BOOL stateStale;
@property(nonatomic, readonly, assign, getter=isRunning) BOOL running;

- (void)updateStateSoon;
- (BOOL)jumpToFile:(NSString *)file line:(NSInteger)line;

// override point
- (void)doUpdateStateInBackground;

// API for subclasses (call on main queue!)
- (void)updateState:(EditorState)state error:(NSError *)error;

@property(nonatomic, assign) NSInteger mruPosition;           // 0..500 or NSNotFound
@property(nonatomic, assign) NSInteger defaultPriority;       // -1 = legacy, 0 = default, 1 = modern, 2 = modern preferred (aka Sublime), 3 = specialized (Coda)
@property(nonatomic, readonly) NSInteger effectivePriority;

@end
