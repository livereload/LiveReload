
#import <Cocoa/Cocoa.h>
#import <Foundation/Foundation.h>

@class ToolError;
@class Editor;


enum UnparsedErrorState {
    UnparsedErrorStateNone,
    UnparsedErrorStateDefault,
    UnparsedErrorStateConnecting,
    UnparsedErrorStateFail,
    UnparsedErrorStateSuccess
};


@interface ToolErrorWindowController : NSWindowController {
    ToolError             *_compilerError;
    NSString              *_key;
    enum UnparsedErrorState _state;

    NSTextField           *_fileNameLabel;
    NSTextField           *_lineNumberLabel;
    NSTextView            *_unparsedView;
    NSTextView            *_messageView;
    NSPopUpButton         *_actionButton;
    NSButton              *_jumpToErrorButton;

    ToolErrorWindowController *_previousWindowController;
    BOOL                   _appearing;
    BOOL                   _suicidal;

    Editor                *_editor;
}

- (id)initWithCompilerError:(ToolError *)compilerError key:(NSString *)key;

@property (assign) IBOutlet NSTextField *fileNameLabel;
@property (assign) IBOutlet NSTextField *lineNumberLabel;
@property (assign) IBOutlet NSTextView *unparsedView;
@property (assign) IBOutlet NSTextView  *messageView;
@property (assign) IBOutlet NSPopUpButton *actionButton;
@property (assign) IBOutlet NSButton *jumpToErrorButton;

- (void)show;

+ (void)hideErrorWindowWithKey:(NSString *)key;

@end
