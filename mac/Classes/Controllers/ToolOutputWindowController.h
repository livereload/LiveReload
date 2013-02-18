
#import <Cocoa/Cocoa.h>
#import <Foundation/Foundation.h>

@class ToolOutput;
@class Editor;


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
    NSPopUpButton         *_actionButton;
    NSButton              *_jumpToErrorButton;

    NSMenuItem            *_showOutputMenuItem;

    ToolOutputWindowController *_previousWindowController;
    BOOL                   _appearing;
    BOOL                   _suicidal;

    Editor                *_editor;

    NSInteger              _submissionResponseCode;
    NSMutableData         *_submissionResponseBody;

    NSURL                 *_specialMessageURL;
}

- (id)initWithCompilerOutput:(ToolOutput *)compilerOutput key:(NSString *)key;

@property (assign) IBOutlet NSTextField *fileNameLabel;
@property (assign) IBOutlet NSTextField *lineNumberLabel;
@property (assign) IBOutlet NSTextView *unparsedNotificationView;
@property (assign) IBOutlet NSTextView  *messageView;
@property (assign) IBOutlet NSScrollView  *messageScroller;
@property (assign) IBOutlet NSPopUpButton *actionButton;
@property (assign) IBOutlet NSButton *jumpToErrorButton;
@property (assign) IBOutlet NSMenuItem *showOutputMenuItem;

- (void)show;

+ (void)hideOutputWindowWithKey:(NSString *)key;

@end
