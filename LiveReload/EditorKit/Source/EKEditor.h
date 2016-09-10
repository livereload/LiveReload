@import Foundation;
#import "EKGlobals.h"


@class EKJumpRequest;


typedef enum {
    EKEditorStateNotFound,
    EKEditorStateBroken,
    EKEditorStateFound,
    EKEditorStateRunning,
} EKEditorState;


@interface EKEditor : NSObject

@property(nonatomic, copy) NSString *identifier;
@property(nonatomic, copy) NSString *displayName;
@property(nonatomic, copy) NSString *cocoaBundleId;

@property(nonatomic, readonly, assign) EKEditorState state;
@property(nonatomic, readonly, assign, getter=isStateStale) BOOL stateStale;
@property(nonatomic, readonly, assign, getter=isRunning) BOOL running;

- (void)updateStateSoon;
- (BOOL)jumpToFile:(NSString *)file line:(NSInteger)line;
- (void)jumpWithRequest:(EKJumpRequest *)request completionHandler:(void(^)(NSError *error))completionHandler;

// override point
- (void)doUpdateStateInBackground;

// API for subclasses (call on main queue!)
- (void)updateState:(EKEditorState)state error:(NSError *)error;

@property(nonatomic, assign) NSInteger mruPosition;           // 0..500 or NSNotFound
@property(nonatomic, assign) NSInteger defaultPriority;       // -1 = legacy, 0 = default, 1 = modern, 2 = modern preferred (aka Sublime), 3 = specialized (Coda)
@property(nonatomic, readonly) NSInteger effectivePriority;

@end


@interface InternalEditor : EKEditor

@end
