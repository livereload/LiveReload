
#import <Foundation/Foundation.h>

typedef enum {
    EditorStateNotFound,
    EditorStateBroken,
    EditorStateFound,
    EditorStateRunning,
} EditorState;


@interface Editor : NSObject

@property(nonatomic, readonly, copy) NSString *displayName;
@property(nonatomic, readonly, assign) EditorState state;
@property(nonatomic, readonly, assign, getter=isStateStale) BOOL stateStale;

- (void)updateStateSoon;
- (BOOL)jumpToFile:(NSString *)file line:(NSInteger)line;

// override point
- (void)doUpdateStateInBackground;

// API for subclasses (call on main queue!)
- (void)updateState:(EditorState)state error:(NSError *)error;

@end
