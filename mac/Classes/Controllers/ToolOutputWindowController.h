
#import <Cocoa/Cocoa.h>
#import <Foundation/Foundation.h>

@class ToolOutput;
@class EKEditor;


enum UnparsedErrorState {
    UnparsedErrorStateNone,
    UnparsedErrorStateDefault,
    UnparsedErrorStateConnecting,
    UnparsedErrorStateFail,
    UnparsedErrorStateSuccess
};


@interface ToolOutputWindowController : NSWindowController {
    ToolOutput            *_compilerOutput;
    NSString              *_key;
    enum UnparsedErrorState _state;

    NSTextField           *_fileNameLabel;
    NSTextField           *_lineNumberLabel;
    NSTextView            *_unparsedNotificationView;
    NSTextView            *_messageView;
    NSScrollView          *_messageScroller;
    NSButton              *_jumpToErrorButton;

    NSMenuItem            *_showOutputMenuItem;

    ToolOutputWindowController *_previousWindowController;
    BOOL                   _appearing;
    BOOL                   _suicidal;

    NSArray               *_editors;

    NSInteger              _submissionResponseCode;
    NSMutableData         *_submissionResponseBody;

    NSURL                 *_specialMessageURL;

    CGRect                 _originalActionControlFrame;

    id                     _selfReferenceDuringAnimation;
}

- (id)initWithCompilerOutput:(ToolOutput *)compilerOutput key:(NSString *)key;

@property (assign) IBOutlet NSTextField *fileNameLabel;
@property (assign) IBOutlet NSTextField *lineNumberLabel;
@property (assign) IBOutlet NSTextView *unparsedNotificationView;
@property (assign) IBOutlet NSTextView  *messageView;
@property (assign) IBOutlet NSScrollView  *messageScroller;
@property (assign) IBOutlet NSButton *jumpToErrorButton;
@property (assign) IBOutlet NSMenuItem *showOutputMenuItem;
@property (assign) IBOutlet NSSegmentedControl *actionControl;
@property (assign) IBOutlet NSMenu *actionMenu;

- (void)show;

+ (void)hideOutputWindowWithKey:(NSString *)key;

@end
