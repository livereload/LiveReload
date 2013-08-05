
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

    NSTextField           *__weak _fileNameLabel;
    NSTextField           *__weak _lineNumberLabel;
    NSTextView            *__unsafe_unretained _unparsedNotificationView;
    NSTextView            *__unsafe_unretained _messageView;
    NSScrollView          *__weak _messageScroller;
    NSButton              *__weak _jumpToErrorButton;

    NSMenuItem            *__weak _showOutputMenuItem;

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

@property (weak) IBOutlet NSTextField *fileNameLabel;
@property (weak) IBOutlet NSTextField *lineNumberLabel;
@property (unsafe_unretained) IBOutlet NSTextView *unparsedNotificationView;
@property (unsafe_unretained) IBOutlet NSTextView  *messageView;
@property (weak) IBOutlet NSScrollView  *messageScroller;
@property (weak) IBOutlet NSButton *jumpToErrorButton;
@property (weak) IBOutlet NSMenuItem *showOutputMenuItem;
@property (weak) IBOutlet NSSegmentedControl *actionControl;
@property (weak) IBOutlet NSMenu *actionMenu;

- (void)show;

+ (void)hideOutputWindowWithKey:(NSString *)key;

@end
